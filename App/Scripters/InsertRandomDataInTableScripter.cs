﻿// Ignore Spelling: Scripter

using Microsoft.Extensions.Configuration;
using Microsoft.SqlServer.Management.Sdk.Sfc;
using Microsoft.SqlServer.Management.Smo;
using Newtonsoft.Json.Linq;
using SqlHelper.Helpers;
using System.Collections.Specialized;
using System.Data.Common;
using System.Globalization;
using System.Text;

namespace SqlHelper.App.Scripters;

internal class InsertRandomDataInTableScripter : IScripter
{
    public string OutputFileName { get; }

    private readonly Scripter scripter;
    private readonly IConfigurationRoot config;
    private readonly Table table;
    private readonly Random rng = new(12345);
    private readonly int rowCount = 10;

    private InsertRandomDataInTableScripter(Server server, IConfigurationRoot config, Table table)
    {
        scripter = new Scripter(server) { Options = OptionBuilder.CreateDefaultDriAllOptions() };
        this.config = config;
        this.table = table;
        OutputFileName = $"{nameof(InsertRandomDataInTableScripter)}_{table.Name}";
    }

    static IScripter IScripter.Create(Server server, Database db, IConfigurationRoot config)
    {
        var schemaName = config[Constants.Settings.TableSchemaName];
        var tableName = config[Constants.Settings.TableName];
        var table = db.Tables[tableName, schemaName] ?? throw new Exception($"Table {schemaName}.{tableName} not found. Please update appsettings.json.");

        return new InsertRandomDataInTableScripter(server, config, table);
    }

    public StringCollection Run()
    {
        var results = new StringCollection();

        var insertableCols = table.Columns
                .Cast<Column>()
                .Where(CouldBeInserted)
                .ToList();

        var jsonCols = new HashSet<string>(
            insertableCols.Where(c => IsJsonConstrained(table, c)).Select(c => c.Name),
            StringComparer.OrdinalIgnoreCase
        );


        if (insertableCols.Count == 0)
        {
            results.Add("No insertable columns (all are identity/computed/sparse).");

            return results;
        }

        var sb = new StringBuilder();
        sb.AppendLine("SET NOCOUNT ON;");
        sb.AppendLine("BEGIN TRY");
        sb.AppendLine("BEGIN TRAN;");

        // Uncomment if you want to ignore FK checks on THIS table only (fast + forgiving):
        // sb.AppendLine($"ALTER TABLE [{TableSchema}].[{TableName}] NOCHECK CONSTRAINT ALL;");

        for (int i = 0; i < rowCount; i++)
        {
            var names = new StringBuilder();
            var values = new StringBuilder();
            bool first = true;

            foreach (var col in insertableCols)
            {
                if (CouldBeInserted(col) == false)
                    continue;

                bool useNull = col.Nullable && rng.NextDouble() < .1;

                if (!first) { names.Append(", "); values.Append(", "); }
                first = false;

                names.AppendLine(Bracket(col.Name));
                values.AppendLine(useNull ? "NULL" : ToSqlLiteral(RandomValue(col, rng, jsonCols)));
            }

            sb.Append("INSERT INTO ")
                .Append(FullName(table.Schema, table.Name))
                .AppendLine(" (")
                .Append(names)
                .AppendLine(") VALUES (")
                .Append(values)
                .AppendLine(");");
        }

        // If you NOCHECKed above, re-enable:
        // sb.AppendLine($"ALTER TABLE [{TableSchema}].[{TableName}] WITH CHECK CHECK CONSTRAINT ALL;");

        sb.AppendLine("COMMIT;");
        sb.AppendLine("END TRY");
        sb.AppendLine("BEGIN CATCH");
        sb.AppendLine("  IF @@TRANCOUNT > 0 ROLLBACK;");
        sb.AppendLine("  THROW;");
        sb.AppendLine("END CATCH;");

        results.Add(sb.ToString());

        return results;
    }

    private static bool CouldBeInserted(Column c)
    {
        return !c.Identity && !c.Computed && !c.IsSparse && !c.InPrimaryKey;
    }

    static string FullName(string schema, string name) => $"{Bracket(schema)}.{Bracket(name)}";
    static string Bracket(string s) => $"[{s.Replace("]", "]]")}]";

    static object RandomValue(Column col, Random rng, HashSet<string> jsonCols)
    {
        if (jsonCols.Contains(col.Name))
            return RandomJson(rng);

        var dt = col.DataType.SqlDataType;

        switch (dt)
        {
            case SqlDataType.Bit: return rng.Next(0, 2);
            case SqlDataType.TinyInt: return rng.Next(0, 256);
            case SqlDataType.SmallInt: return (short)rng.Next(short.MinValue, short.MaxValue);
            case SqlDataType.Int: return rng.Next(int.MinValue / 2, int.MaxValue / 2);
            case SqlDataType.BigInt: return NextLong(rng, -9_000_000_000L, 9_000_000_000L);

            case SqlDataType.Decimal:
            case SqlDataType.Numeric:
                {
                    int precision = col.DataType.NumericPrecision > 0 ? col.DataType.NumericPrecision : 18;
                    int scale = col.DataType.NumericScale > 0 ? col.DataType.NumericScale : Math.Min(precision, 4);
                    decimal maxIntPart = (decimal)Math.Pow(10, Math.Max(1, precision - scale)) - 1;
                    decimal whole = (decimal)rng.Next(0, (int)Math.Min(maxIntPart, int.MaxValue));
                    decimal frac = scale > 0 ? Math.Round((decimal)rng.NextDouble(), scale) : 0m;
                    var val = whole + frac;
                    if (rng.NextDouble() < 0.5) val = -val;
                    return Math.Round(val, scale);
                }

            case SqlDataType.Money:
            case SqlDataType.SmallMoney:
                return Math.Round((decimal)(rng.NextDouble() * 200000 - 100000), 4);

            case SqlDataType.Float:
            case SqlDataType.Real:
                return rng.NextDouble() * (rng.NextDouble() < 0.5 ? -1 : 1) * 1_000_000.0;

            case SqlDataType.Date:
                return RandomDate(rng, new DateTime(2005, 1, 1), DateTime.Today).Date;

            case SqlDataType.DateTime:
            case SqlDataType.SmallDateTime:
            case SqlDataType.DateTime2:
                return RandomDate(rng, new DateTime(2005, 1, 1), DateTime.UtcNow);

            case SqlDataType.DateTimeOffset:
                return new DateTimeOffset(RandomDate(rng, new DateTime(2005, 1, 1), DateTime.UtcNow),
                                          TimeSpan.FromHours(rng.Next(-12, 13)));

            case SqlDataType.Time:
                return new TimeSpan(0, rng.Next(0, 24 * 60), rng.Next(0, 60));

            case SqlDataType.UniqueIdentifier:
                return Guid.NewGuid();

            case SqlDataType.NVarChar:
            case SqlDataType.VarChar:
            case SqlDataType.NChar:
            case SqlDataType.Char:
                {
                    int maxLen = MaxLen(col);
                    int len = Math.Max(1, Math.Min(maxLen, 1 + rng.Next(Math.Min(32, maxLen))));
                    return RandomString(rng, len);
                }

            case SqlDataType.Text:
            case SqlDataType.NText:
                return RandomString(rng, 64 + rng.Next(192));

            case SqlDataType.VarBinary:
            case SqlDataType.Binary:
            case SqlDataType.Image:
                {
                    int maxLen = MaxLen(col);
                    int len = Math.Min(maxLen > 0 ? maxLen : 16, 16);
                    return RandomBytesHex(rng, len);
                }

            case SqlDataType.Xml:
                return $"<note id=\"{Guid.NewGuid()}\"><body>{RandomString(rng, 24)}</body></note>";

            default:
                return RandomString(rng, 12);
        }
    }

    static int MaxLen(Column col)
    {
        var l = col.DataType.MaximumLength;   // -1 for (MAX)
        if (l < 0) l = 256;
        return Math.Max(1, l);
    }

    static string ToSqlLiteral(object? v)
    {
        if (v == null) return "NULL";
        switch (v)
        {
            case int i: return i.ToString(CultureInfo.InvariantCulture);
            case long l: return l.ToString(CultureInfo.InvariantCulture);
            case short s: return s.ToString(CultureInfo.InvariantCulture);
            case byte b: return b.ToString(CultureInfo.InvariantCulture);
            case decimal d: return d.ToString(CultureInfo.InvariantCulture);
            case double d2: return d2.ToString("R", CultureInfo.InvariantCulture);
            case float f: return f.ToString("R", CultureInfo.InvariantCulture);
            case bool bo: return bo ? "1" : "0";
            case Guid g: return $"'{g:D}'";
            case DateTime dt: return $"'{dt:yyyy-MM-ddTHH:mm:ss.fffffff}'";
            case DateTimeOffset dto: return $"'{dto:yyyy-MM-ddTHH:mm:ss.fffffffK}'";
            case TimeSpan ts: return $"'{ts:hh\\:mm\\:ss\\.fffffff}'";
            case string s: return "N'" + s.Replace("'", "''") + "'";
            default:
                var str = v.ToString() ?? "";
                if (str.StartsWith("0x", StringComparison.OrdinalIgnoreCase)) return str; // varbinary hex
                return "N'" + str.Replace("'", "''") + "'";
        }
    }

    static string RandomString(Random rng, int len)
    {
        const string alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 _-";
        var sb = new StringBuilder(len);
        for (int i = 0; i < len; i++) sb.Append(alphabet[rng.Next(alphabet.Length)]);
        return sb.ToString();
    }

    static string RandomBytesHex(Random rng, int len)
    {
        var bytes = new byte[len];
        rng.NextBytes(bytes);
        var sb = new StringBuilder(2 + len * 2);
        sb.Append("0x");
        foreach (var b in bytes) sb.Append(b.ToString("X2"));
        return sb.ToString();
    }

    static long NextLong(Random rng, long minInclusive, long maxInclusive)
    {
        var buf = new byte[8];
        rng.NextBytes(buf);
        long val = BitConverter.ToInt64(buf, 0) & long.MaxValue;
        long range = maxInclusive - minInclusive + 1;
        return minInclusive + (val % range);
    }

    static DateTime RandomDate(Random rng, DateTime min, DateTime max)
    {
        var span = max - min;
        var sec = rng.NextDouble() * span.TotalSeconds;
        return min.AddSeconds(sec);
    }

    // NEW: detect JSON constraint via table CHECKs that reference this column
    static bool IsJsonConstrained(Table tbl, Column col)
    {
        string colToken = "[" + col.Name.Replace("]", "]]") + "]";
        foreach (Check chk in tbl.Checks)
        {
            var text = chk.Text ?? string.Empty;
            if (text.IndexOf(colToken, StringComparison.OrdinalIgnoreCase) >= 0)
            {
                if (text.IndexOf("ISJSON", StringComparison.OrdinalIgnoreCase) >= 0) return true;
                if (text.IndexOf("JSON_VALUE", StringComparison.OrdinalIgnoreCase) >= 0) return true;
                if (text.IndexOf("JSON_QUERY", StringComparison.OrdinalIgnoreCase) >= 0) return true;
                if (text.IndexOf("OPENJSON", StringComparison.OrdinalIgnoreCase) >= 0) return true;
            }
        }
        return false;
    }

    // NEW: small random JSON generator (object with mixed primitives/arrays)
    static string RandomJson(Random rng)
    {
        int props = 3 + rng.Next(5); // 3..7 properties
        var sb = new StringBuilder();
        sb.Append('{');
        for (int i = 0; i < props; i++)
        {
            if (i > 0) sb.Append(',');
            string key = "k" + rng.Next(1000);
            sb.Append('"').Append(key).Append("\":");

            switch (rng.Next(5))
            {
                case 0: // string
                    sb.Append('"')
                      .Append(RandomString(rng, 1 + rng.Next(8)).Replace("\"", "\\\""))
                      .Append('"');
                    break;
                case 1: // int
                    sb.Append(rng.Next(-1000, 1001));
                    break;
                case 2: // double
                    sb.Append(rng.NextDouble().ToString("R", System.Globalization.CultureInfo.InvariantCulture));
                    break;
                case 3: // bool
                    sb.Append(rng.Next(2) == 0 ? "true" : "false");
                    break;
                default: // small int array
                    sb.Append('[');
                    int n = rng.Next(1, 4);
                    for (int j = 0; j < n; j++)
                    {
                        if (j > 0) sb.Append(',');
                        sb.Append(rng.Next(0, 100));
                    }
                    sb.Append(']');
                    break;
            }
        }
        sb.Append('}');
        return sb.ToString();
    }

}
