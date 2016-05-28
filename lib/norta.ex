defmodule Norta do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Start the endpoint when the application starts
      supervisor(Norta.Endpoint, []),
      # Start the Ecto repository
      supervisor(Norta.Repo, [])
    ]

    if Mix.env != :test do
      # This Agent loads the GTFS routes
      children = children ++ [worker(Norta.GTFSAgent, [])]
      # This GenEvent is for dispatching vehicle updates
      children = children ++ [worker(Norta.Feed.EventManager, [])]
      # This Agent holds the state about Stale vehicles
      children = children ++ [worker(Norta.Feed.StaleAgent, [])]
      # This GenServer fetches and dispatches vehicle updates
      children = children ++ [worker(Norta.Feed.Fetcher, [])]
    end

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Norta.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Norta.Endpoint.config_change(changed, removed)
    :ok
  end
end
