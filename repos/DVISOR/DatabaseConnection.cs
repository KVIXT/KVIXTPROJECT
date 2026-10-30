using Npgsql;
using System;

public class DatabaseConnection
{
    private readonly string _connectionString =
    "Host=localhost;Port=5432;Database=MyDataBase;Username=dota2;Password=12345678";
    public NpgsqlConnection GetConnection()
    {
        var connection = new NpgsqlConnection(_connectionString);
        connection.Open();
        return connection;
    }

    public bool TestConnection()
    {
        try
        {
            using (var connection = GetConnection())
            {
                connection.Close();
                return true;
            }
        }
        catch
        {
            return false;
        }
    }
}