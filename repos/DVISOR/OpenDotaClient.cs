using System;
using System.Net.Http;
using System.Threading.Tasks;

public class OpenDotaClient
{
    private readonly HttpClient _httpClient = new HttpClient();
    private const string BaseUrl = "https://api.opendota.com/api";

    public async Task<string> GetPlayerDataAsync(string steamId)
    {
        try
        {
            var response = await _httpClient.GetAsync($"{BaseUrl}/players/{steamId}");
            if (response.IsSuccessStatusCode)
                return await response.Content.ReadAsStringAsync();
        }
        catch (Exception ex)
        {
            System.Windows.Forms.MessageBox.Show($"Ошибка OpenDota: {ex.Message}");
        }
        return null;
    }

    public async Task<string> GetPlayerMatchesAsync(string steamId, int limit = 20)
    {
        try
        {
            var response = await _httpClient.GetAsync($"{BaseUrl}/players/{steamId}/matches?limit={limit}");
            if (response.IsSuccessStatusCode)
                return await response.Content.ReadAsStringAsync();
        }
        catch (Exception ex)
        {
            System.Windows.Forms.MessageBox.Show($"Ошибка при загрузке матчей: {ex.Message}");
        }
        return null;
    }
}