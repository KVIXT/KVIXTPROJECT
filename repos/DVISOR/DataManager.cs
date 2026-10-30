using Npgsql;
using System;
using System.Data;
using System.Windows.Forms;

public class DataManager
{
    private DatabaseConnection _db = new DatabaseConnection();

    public DataTable GetPlayerProfiles()
    {
        var table = new DataTable();
        try
        {
            using (var connection = _db.GetConnection())
            {
                var command = connection.CreateCommand();
                command.CommandText = "SELECT profile_id, steam_id, player_name, rank, mmr, total_matches, total_wins FROM player_profiles ORDER BY mmr DESC";
                var adapter = new NpgsqlDataAdapter(command);
                adapter.Fill(table);
            }
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Ошибка: {ex.Message}");
        }
        return table;
    }

    public DataTable GetMatches(int profileId)
    {
        var table = new DataTable();
        try
        {
            using (var connection = _db.GetConnection())
            {
                var command = connection.CreateCommand();
                command.CommandText = "SELECT m.match_id, m.played_at, m.duration_seconds, m.result, m.side, m.player_mmr_at_match FROM matches m WHERE m.profile_id = @profileId ORDER BY m.played_at DESC LIMIT 10";
                command.Parameters.AddWithValue("@profileId", profileId);
                var adapter = new NpgsqlDataAdapter(command);
                adapter.Fill(table);
            }
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Ошибка: {ex.Message}");
        }
        return table;
    }

    public DataTable GetPlayerStats(int profileId)
    {
        var table = new DataTable();
        try
        {
            using (var connection = _db.GetConnection())
            {
                var command = connection.CreateCommand();
                command.CommandText = "SELECT h.name, phs.total_matches, phs.wins, ROUND(100.0 * phs.wins / phs.total_matches, 1) AS winrate FROM player_hero_stats phs JOIN heroes h ON phs.hero_id = h.hero_id WHERE phs.profile_id = @profileId ORDER BY phs.total_matches DESC LIMIT 20";
                command.Parameters.AddWithValue("@profileId", profileId);
                var adapter = new NpgsqlDataAdapter(command);
                adapter.Fill(table);
            }
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Ошибка: {ex.Message}");
        }
        return table;
    }

    public DataTable GetRoleStats(int profileId)
    {
        var table = new DataTable();
        try
        {
            using (var connection = _db.GetConnection())
            {
                var command = connection.CreateCommand();
                command.CommandText = "SELECT role, total_matches, wins, losses, ROUND(100.0 * wins / total_matches, 1) AS winrate FROM player_role_stats WHERE profile_id = @profileId ORDER BY total_matches DESC";
                command.Parameters.AddWithValue("@profileId", profileId);
                var adapter = new NpgsqlDataAdapter(command);
                adapter.Fill(table);
            }
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Ошибка: {ex.Message}");
        }
        return table;
    }

    public DataTable SearchHeroes(string minWR, string heroName)
    {
        var table = new DataTable();
        try
        {
            using (var connection = _db.GetConnection())
            {
                var command = connection.CreateCommand();
                command.CommandText = "SELECT h.name, phs.total_matches, phs.wins, ROUND(100.0 * phs.wins / phs.total_matches, 1) AS winrate FROM player_hero_stats phs JOIN heroes h ON phs.hero_id = h.hero_id WHERE (100.0 * phs.wins / phs.total_matches) >= @minWR ORDER BY winrate DESC";
                command.Parameters.AddWithValue("@minWR", double.Parse(minWR));
                var adapter = new NpgsqlDataAdapter(command);
                adapter.Fill(table);
            }
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Ошибка: {ex.Message}");
        }
        return table;
    }

    public DataTable GetMatchDetails(int matchId)
    {
        var table = new DataTable();
        try
        {
            using (var connection = _db.GetConnection())
            {
                var command = connection.CreateCommand();
                command.CommandText = "SELECT mp.match_player_id, h.name, mp.role, mp.kills, mp.deaths, mp.assists, mp.gpm, mp.xpm, mp.last_hits, mp.denies, mp.performance_score, CASE WHEN mp.is_game_mvp THEN '★ MVP' ELSE '' END as mvp FROM match_players mp JOIN heroes h ON mp.hero_id = h.hero_id WHERE mp.match_id = @matchId ORDER BY mp.performance_score DESC";
                command.Parameters.AddWithValue("@matchId", matchId);
                var adapter = new NpgsqlDataAdapter(command);
                adapter.Fill(table);
            }
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Ошибка: {ex.Message}");
        }
        return table;
    }
}