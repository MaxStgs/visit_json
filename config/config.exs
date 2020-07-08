import Config

config :visit_json, port: 4000, redis_port: 6379

import_config "#{Mix.env()}.exs"