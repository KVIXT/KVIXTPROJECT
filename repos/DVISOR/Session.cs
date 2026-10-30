using System;

public static class Session
{
    public static PlayerProfile CurrentUser { get; set; }
}

public class PlayerProfile
{
    public int profile_id { get; set; }
    public long steam_id { get; set; }
    public string player_name { get; set; }
    public string rank { get; set; }
    public int mmr { get; set; }
    public int total_matches { get; set; }
    public int total_wins { get; set; }
    public bool is_admin { get; set; }
    public string avatar_url { get; set; }
}