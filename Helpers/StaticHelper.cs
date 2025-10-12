// Ignore Spelling: scripter

using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using Microsoft.SqlServer.Management.Common;
using Microsoft.SqlServer.Management.Smo;
using SqlHelper.App;
using System.Collections.Specialized;

namespace SqlHelper.Helpers;

public static class StaticHelper
{
    public static void ConnectToDb(out SqlConnection sqlConn, out Server server, out Database db, out AppSettings settings)
    {
        var config = new ConfigurationBuilder()
            .SetBasePath(AppContext.BaseDirectory)
            .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
            .AddJsonFile("appsettings.Development.json", optional: true, reloadOnChange: true)
            .AddUserSecrets<Program>(optional: true, reloadOnChange: true)
            .Build();

        settings = new();
        config.Bind(settings);

        // read values directly without a class
        string serverName = settings.Connection.ServerName;
        string databaseName = settings.Connection.DatabaseName;

        Console.WriteLine($"Server:   {serverName}");
        Console.WriteLine($"Database: {databaseName}");

        sqlConn = CreateDefaultSqlConnection(serverName, databaseName);
        var svrConn = new ServerConnection(sqlConn);
        server = new Server(svrConn);
        db = server.Databases[databaseName] ?? throw new Exception($"DB '{databaseName}' not found.");
    }

    public static SqlConnection CreateDefaultSqlConnection(string serverName, string databaseName)
    {
        SqlConnection sqlConn;
        // Use SQL Auth:
        var csb = new SqlConnectionStringBuilder
        {
            DataSource = serverName,
            InitialCatalog = databaseName,

            //UserID = "sa",            // or your SQL login
            //Password = "YourPassword",
            //TrustServerCertificate = true

            IntegratedSecurity = true,   // <-- Windows Auth
            Encrypt = true,              // keep if your server enforces TLS
            TrustServerCertificate = true // optional for dev; prefer real certs in prod
        };

        sqlConn = new SqlConnection(csb.ConnectionString);
        return sqlConn;
    }

    public static string GetOutputPath(IScripter scripter)
    {
        string exeDir = AppDomain.CurrentDomain.BaseDirectory;
        string projectDir = Path.GetFullPath(Path.Combine(exeDir, @"..\..\.."));
        var outputFile = Path.Combine(projectDir, "Generated", $"{scripter.OutputFileName}.sql");

        return outputFile;
    }

    public static string[] ToStringArray(StringCollection sc)
    {
        var arr = new string[sc.Count];
        sc.CopyTo(arr, 0);
        return arr;
    }
}
