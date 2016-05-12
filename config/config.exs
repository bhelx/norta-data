# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :norta, Norta.Endpoint,
  url: [host: "localhost"],
  root: Path.dirname(__DIR__),
  secret_key_base: "n7iDB+LrFRGtN6cV6Q+1bEM7mx2jEtXc3IblmwoUgf1cyy6rbumeK1+kod7QBUgS",
  render_errors: [accepts: ~w(html json)],
  pubsub: [name: Norta.PubSub,
           adapter: Phoenix.PubSub.PG2]

config :norta, api_key: System.get_env("NORTA_API_KEY")

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"

# Configure phoenix generators
config :phoenix, :generators,
  migration: true,
  binary_id: false
