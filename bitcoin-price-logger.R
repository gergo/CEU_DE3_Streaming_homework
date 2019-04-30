library(binancer)
prices <- binance_coins_prices()
library(futile.logger)
flog.info('The current Bitcoin price is: %s', prices[symbol == 'BTC', usd])
