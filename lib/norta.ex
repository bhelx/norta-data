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
      children = children ++ [worker(Norta.GtfsAgent, [])]
      # This GenEvent is for dispatching vehicle updates
      children = children ++ [worker(GenEvent, [[name: :feed_event_stream]])]
      # This worker fetches and dispatches vehicle updates
      children = children ++ [worker(Norta.Feed.Fetcher, [])]
    end

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Norta.Supervisor]
    {:ok, sup} = Supervisor.start_link(children, opts)

    if Mix.env != :test do
      GenEvent.add_handler(:feed_event_stream, Norta.Feed.ChannelBroadcastHandler, %{})
      GenEvent.add_handler(:feed_event_stream, Norta.Feed.LoggingHandler, %{})
    end

    {:ok, sup}
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Norta.Endpoint.config_change(changed, removed)
    :ok
  end
end
