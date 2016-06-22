defmodule Norta.Feed.EventManager do
  use GenServer
  require Logger

  @name __MODULE__
  @dispatcher Norta.Feed.EventStream

  def start_link do
    GenServer.start_link(@name, [], [name: @name])
  end

  def notify(event, payload) do
    GenServer.cast(@name, {event, payload})
  end

  def init(_) do
    GenEvent.start_link(name: @dispatcher)
    register_handlers()
    {:ok, []}
  end

  def handle_cast({event, payload}, state) do
    GenEvent.notify(@dispatcher, {event, payload})
    {:noreply, state}
  end

  @doc "Handles the exit message from crashed, monitored GenEvent handlers"
  def handle_info({:gen_event_EXIT, crashed_handler, error}, state) do
    Logger.error("#{crashed_handler} crashed. Restarting #{@name}.")
    {:stop, {:handler_died, error}, state}
  end

  defp register_handlers do
    GenEvent.add_mon_handler(@dispatcher, Norta.Feed.ChannelBroadcastHandler, %{})
    GenEvent.add_mon_handler(@dispatcher, Norta.Feed.LoggingHandler, %{})
  end
end
