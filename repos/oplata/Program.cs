using System.Collections.Concurrent;
using System.Globalization;
using System.Net.Http.Json;
using System.Text.Json.Serialization;
using Telegram.Bot;
using Telegram.Bot.Polling;
using Telegram.Bot.Types;
using Telegram.Bot.Types.ReplyMarkups;


const decimal priceUsd = 299m;

var botToken = "8656053772:AAEqczLhdLwkzRpyjQwEIAF_t6QXJ3FJyoo";
var cryptoPayToken = "642360:AA6KG5PgaWP8TERtEdCCTHFW8lEoiqRSKYO";
long adminId = 7885469929; // замени на свой Telegram ID

var bot = new TelegramBotClient(botToken);

using var http = new HttpClient
{
    BaseAddress = new Uri("https://pay.crypt.bot/api/")
};
http.DefaultRequestHeaders.Add("Crypto-Pay-API-Token", cryptoPayToken);

// Эти данные хранятся только в памяти и пропадут после перезапуска бота.
var invoicesByUser = new ConcurrentDictionary<long, long>();
var processedInvoices = new ConcurrentDictionary<long, byte>();

using var cts = new CancellationTokenSource();

bot.StartReceiving(
    HandleUpdateAsync,
    HandleErrorAsync,
    new ReceiverOptions(),
    cts.Token);

Console.WriteLine("Бот запущен. Напиши ему /start в Telegram.");

await Task.Delay(Timeout.Infinite, cts.Token);

async Task HandleUpdateAsync(
    ITelegramBotClient client,
    Update update,
    CancellationToken cancellationToken)
{
if (update.Message?.Text == "/start")
{
    var keyboard = new InlineKeyboardMarkup(new[]
    {
        new[]
        {
            InlineKeyboardButton.WithCallbackData("Купить", "buy"),
            InlineKeyboardButton.WithCallbackData("Проверить оплату", "check")
        }
    });

    var videoPath = Path.Combine(AppContext.BaseDirectory, "welcome.mp4");

    if (!File.Exists(videoPath))
    {
        Console.WriteLine($"Видео не найдено: {videoPath}");
        await client.SendMessage(
            update.Message.Chat.Id,
            "Не могу найти файл welcome.mp4.",
            cancellationToken: cancellationToken);
        return;
    }

    await using var video = File.OpenRead(videoPath);

    await client.SendVideo(
        chatId: update.Message.Chat.Id,
        video: InputFile.FromStream(video, "welcome.mp4"),
        caption: $"Добро пожаловать! Здесь можно получить доступ к закрытому каналу с Детским контентом что ты так искал.\nЦена: {priceUsd} USD.",
        replyMarkup: keyboard,
        cancellationToken: cancellationToken);

    return;
}

    if (update.CallbackQuery is not { } callback)
        return;

    await client.AnswerCallbackQuery(
        callback.Id,
        cancellationToken: cancellationToken);

    if (callback.Message is not { } callbackMessage)
        return;

    var userId = callbackMessage.Chat.Id;

    if (callback.Data == "buy")
    {
        try
        {
            var invoice = await CreateInvoiceAsync(userId, cancellationToken);
            invoicesByUser[userId] = invoice.InvoiceId;

            await client.SendMessage(
                userId,
                $"Счёт на {priceUsd} USD создан:\n{invoice.PayUrl}\n\nПосле оплаты нажмите «Проверить оплату».",
                cancellationToken: cancellationToken);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Ошибка создания счёта: {ex}");

            await client.SendMessage(
                userId,
                "Не удалось создать счёт. Попробуйте позже.",
                cancellationToken: cancellationToken);
        }

        return;
    }

    if (callback.Data == "check")
    {
        if (!invoicesByUser.TryGetValue(userId, out var invoiceId))
        {
            await client.SendMessage(
                userId,
                "Сначала нажмите «Купить», чтобы получить счёт.",
                cancellationToken: cancellationToken);

            return;
        }

        try
        {
            var isPaid = await IsInvoicePaidAsync(invoiceId, cancellationToken);

            if (!isPaid)
            {
                await client.SendMessage(
                    userId,
                    "Оплата пока не найдена. Подождите немного и нажмите «Проверить оплату» ещё раз.",
                    cancellationToken: cancellationToken);

                return;
            }

            if (processedInvoices.TryAdd(invoiceId, 0))
            {
                await client.SendMessage(
                    adminId,
                    $"Оплата получена: {priceUsd} USD.\nTelegram ID покупателя: {userId}",
                    cancellationToken: cancellationToken);

                await client.SendMessage(
                    userId,
                    "Оплата подтверждена! Напишите продавцу свой @username для получения доступа.",
                    cancellationToken: cancellationToken);
            }
            else
            {
                await client.SendMessage(
                    userId,
                    "Эта оплата уже обработана. Если доступ ещё не выдан, напишите продавцу.",
                    cancellationToken: cancellationToken);
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Ошибка проверки оплаты: {ex}");

            await client.SendMessage(
                userId,
                "Не удалось проверить оплату. Попробуйте позже.",
                cancellationToken: cancellationToken);
        }
    }
}

async Task<InvoiceResult> CreateInvoiceAsync(
    long userId,
    CancellationToken cancellationToken)
{
    var response = await http.PostAsJsonAsync(
        "createInvoice",
        new
        {
            amount = priceUsd.ToString("0.00", CultureInfo.InvariantCulture),
            currency_type = "fiat",
            fiat = "USD",
            accepted_assets = "USDT,TON,BTC",
            payload = userId.ToString(),
            description = "Доступ в канал"
        },
        cancellationToken);

    response.EnsureSuccessStatusCode();

    var data = await response.Content.ReadFromJsonAsync<CryptoResponse<InvoiceResult>>(
        cancellationToken: cancellationToken);

    if (data?.Ok != true || data.Result is null)
        throw new Exception(data?.Error?.Message ?? "Crypto Pay не вернул счёт.");

    return data.Result;
}

async Task<bool> IsInvoicePaidAsync(
    long invoiceId,
    CancellationToken cancellationToken)
{
    var response = await http.GetAsync(
        $"getInvoices?invoice_ids={invoiceId}",
        cancellationToken);

    response.EnsureSuccessStatusCode();

    var data = await response.Content.ReadFromJsonAsync<CryptoResponse<InvoiceList>>(
        cancellationToken: cancellationToken);

    if (data?.Ok != true || data.Result is null)
        throw new Exception(data?.Error?.Message ?? "Crypto Pay не вернул статус счёта.");

    return data.Result.Items.Any(invoice =>
        invoice.InvoiceId == invoiceId &&
        invoice.Status == "paid");
}

Task HandleErrorAsync(
    ITelegramBotClient client,
    Exception exception,
    CancellationToken cancellationToken)
{
    Console.WriteLine(exception);
    return Task.CompletedTask;
}

public sealed class CryptoResponse<T>
{
    [JsonPropertyName("ok")]
    public bool Ok { get; set; }

    [JsonPropertyName("result")]
    public T? Result { get; set; }

    [JsonPropertyName("error")]
    public CryptoError? Error { get; set; }
}

public sealed class CryptoError
{
    [JsonPropertyName("message")]
    public string? Message { get; set; }
}

public sealed class InvoiceResult
{
    [JsonPropertyName("invoice_id")]
    public long InvoiceId { get; set; }

    [JsonPropertyName("pay_url")]
    public string PayUrl { get; set; } = "";
}

public sealed class InvoiceList
{
    [JsonPropertyName("items")]
    public List<InvoiceItem> Items { get; set; } = new();
}

public sealed class InvoiceItem
{
    [JsonPropertyName("invoice_id")]
    public long InvoiceId { get; set; }

    [JsonPropertyName("status")]
    public string Status { get; set; } = "";
}