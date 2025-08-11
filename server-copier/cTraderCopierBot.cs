// Developer: Branson Alexander
// Description: cTrader Copier Bot (Master/Slave) via HTTP requests

using System;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using cAlgo.API;
using Newtonsoft.Json;

namespace cAlgo
{
    [Robot(Name = "cTrader Copier Bot", Description = "Copy trades as Master or Slave via HTTP (Developer: Branson Alexander)", TimeZone = TimeZones.UTC, AccessRights = AccessRights.FullAccess)]
    public class cTraderCopierBot : Robot
    {
        [Parameter("Mode", DefaultValue = "master")]
        public string Mode { get; set; } // "master" or "slave"

        [Parameter("Request Interval (ms)", DefaultValue = 1000)]
        public int Interval { get; set; }

        private HttpClient _httpClient;
        private string serverUrl = "http://localhost:3000";

        protected override void OnStart()
        {
            _httpClient = new HttpClient();

            if (Mode.ToLower() == "slave")
                Timer.Start(TimeSpan.FromMilliseconds(Interval));

            Print($"cTraderCopierBot started in {Mode} mode.");
        }

        protected override void OnStop()
        {
            _httpClient.Dispose();
        }

        protected override void OnTradeOpened(TradeOpenedEventArgs args)
        {
            if (Mode.ToLower() != "master") return;

            var trade = args.Trade;
            var payload = new
            {
                type = "open",
                symbol = trade.SymbolName,
                volume = trade.Volume,
                side = trade.TradeType.ToString(),
                price = trade.EntryPrice,
                id = trade.Id,
                time = Server.Time.ToString("o")
            };
            SendToServer(payload);
        }

        protected override void OnTradeClosed(TradeClosedEventArgs args)
        {
            if (Mode.ToLower() != "master") return;

            var trade = args.Trade;
            var payload = new
            {
                type = "close",
                symbol = trade.SymbolName,
                volume = trade.Volume,
                side = trade.TradeType.ToString(),
                price = trade.ClosePrice,
                id = trade.Id,
                time = Server.Time.ToString("o")
            };
            SendToServer(payload);
        }

        private async void SendToServer(object data)
        {
            try
            {
                string json = JsonConvert.SerializeObject(data);
                var content = new StringContent(json, Encoding.UTF8, "application/json");
                var response = await _httpClient.PostAsync(serverUrl + "/copy", content);
                Print($"Sent to server: {response.StatusCode}");
            }
            catch (Exception ex)
            {
                Print("Error sending data: " + ex.Message);
            }
        }

        protected override void OnTimer()
        {
            if (Mode.ToLower() != "slave") return;
            Task.Run(() => CheckForOrders());
        }

        private async Task CheckForOrders()
        {
            try
            {
                var response = await _httpClient.GetAsync(serverUrl + "/orders");
                var content = await response.Content.ReadAsStringAsync();
                if (!string.IsNullOrWhiteSpace(content))
                {
                    dynamic instructions = JsonConvert.DeserializeObject(content);
                    foreach (var order in instructions)
                    {
                        string type = order.type;
                        string symbol = order.symbol;
                        double volume = order.volume;
                        string side = order.side;

                        var symbolObj = MarketData.GetSymbol(symbol);
                        TradeType tradeType = side.ToLower() == "buy" ? TradeType.Buy : TradeType.Sell;

                        if (type == "open")
                        {
                            ExecuteMarketOrder(tradeType, symbolObj.Name, volume);
                        }
                        else if (type == "close")
                        {
                            foreach (var position in Positions.FindAll(symbol, tradeType))
                            {
                                ClosePosition(position);
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Print("Error checking orders: " + ex.Message);
            }
        }
    }
}
