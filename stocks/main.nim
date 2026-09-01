## stocks — real-time quotes for US-listed tickers via Nasdaq's public API.
##
## Data: Nasdaq API (https://api.nasdaq.com), free public endpoint, no API key
## needed. Quotes for US equities (NASDAQ, NYSE, AMEX). A browser User-Agent
## is required by the endpoint, and errors surface as structured exceptions.

import std/[httpclient, json, strutils]
import niffler/sdk

let comp = newComponent("stocks", "0.1.0")

proc client(): HttpClient =
  ## Nasdaq's API rejects requests without a browser-like User-Agent.
  newHttpClient("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 " &
                "(KHTML, like Gecko) Chrome/120.0 Safari/537.36",
                timeout = 15_000)

proc nasdaqQuote(symbol: string): JsonNode =
  ## Fetch the raw quote payload for a symbol; raises ValueError when the
  ## symbol does not exist.
  let c = client()
  defer: c.close()
  let url = "https://api.nasdaq.com/api/quote/" & symbol.toUpperAscii() &
            "/info?assetclass=stocks"
  let resp = c.getContent(url).parseJson()
  let data = resp{"data"}
  if data == nil or data.kind == JNull:
    let code = resp{"status", "rCode"}.getInt(-1)
    if code == 400:
      raise newException(ValueError, "unknown ticker symbol: " & symbol)
    raise newException(IOError, "nasdaq quote failed (rCode " & $code & ")")
  result = data

proc parsePrice(s: string): float =
  ## Parse "$1,234.56" and "-0.42%" style strings into a number.
  result = s.replace("$", "").replace(",", "").replace("%", "").strip().parseFloat()

comp.tool:
  proc stocks_quote(symbol: string): JsonNode =
    ## Latest quote for a US-listed stock: price, change, change percent,
    ## volume and 52-week range. Use for "what's the price of X?" questions.
    ## - symbol: ticker symbol, e.g. "NBIS", "AAPL" or "TSLA"
    let q = nasdaqQuote(symbol)
    let p = q{"primaryData"}
    return %*{"symbol": symbol.toUpperAscii(),
              "name": q{"companyName"}.getStr(""),
              "price": parsePrice(p{"lastSalePrice"}.getStr("")),
              "change": parsePrice(p{"netChange"}.getStr("")),
              "changePct": parsePrice(p{"percentageChange"}.getStr("")),
              "volume": p{"volume"}.getStr(""),
              "lastTrade": p{"lastTradeTimestamp"}.getStr(""),
              "fiftyTwoWeekRange":
                q{"keyStats", "fiftyTwoWeekHighLow", "value"}.getStr("")}

# Slash-command surface for interactive UIs (docs/WIRE.md): /quote becomes
# available in the TUI with tab completion for the symbol argument, and runs
# the same stocks_quote tool.
discard comp.slashCommand("quote",
  "Latest quote for a US-listed stock (e.g. /quote NVDA)",
  params = %*[
    %*{"name": "symbol", "kind": "string",
       "description": "ticker symbol, e.g. NBIS, AAPL or TSLA"}
  ],
  tool = "stocks_quote")

comp.run()
