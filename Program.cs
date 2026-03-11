using Microsoft.Extensions.Configuration;
using Microsoft.SqlServer.Management.Smo;
using SqlHelper.App;
using SqlHelper.App.Scripters;
using SqlHelper.Helpers;
using System.Collections.Specialized;
using static SqlHelper.Helpers.StaticHelper;

class Program
{
    static void Main(string[] args)
    {
        //RunScripter<CreateColumnScripter>(out var outputFilePath);
        //Console.WriteLine($"Script written to: {outputFilePath}");

        //RunScripter<CreateColumnScripter.DropColumnScripter>(out var outputFilePath2);
        //Console.WriteLine($"Script written to: {outputFilePath2}");

        //RunScripter<CreateTableScripter>(out var outputFilePath3);
        //Console.WriteLine($"Script written to: {outputFilePath3}");

        RunScripter<InsertRandomDataInTableScripter>(out var outputFilePath4);
        Console.WriteLine($"Script written to: {outputFilePath4}");
    }

    private static void RunScripter<T>(out string outputFilePath) where T : IScripter
    {
        ConnectToDb(out var sqlConn, out var server, out var db, out var appSettings);

        IScripter scripter = CreateScripter<T>(server, db, appSettings);

        StringCollection lines = scripter.Run();

        outputFilePath = GetOutputPath(scripter);

        Directory.CreateDirectory(Path.GetDirectoryName(outputFilePath)!);
        File.WriteAllLines(outputFilePath, ToStringArray(lines).Select(l => $"{l}\n"));
    }

    private static IScripter CreateScripter<T>(Server server, Database db, AppSettings appSettings) where T : IScripter
    {
        return T.Create(server, db, appSettings);
    }
}
