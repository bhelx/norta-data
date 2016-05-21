defmodule Norta.Feed.LoggingHandler do
  use GenEvent, otp_app: :norta
  require Logger
  alias Norta.Repo
  alias Norta.ServerResponse

  def handle_event({:server_response, payload}, state) do
    Logger.info("Got server response #{payload[:code]}")
    server_response_for(payload)
    |> Repo.insert!

    {:ok, state}
  end
  def handle_event({:vehicles, payload}, state) do
    Logger.info("Got vehicles event")
    {:ok, state}
  end

  def server_response_for(payload = %{code: :md5_match}) do
    %ServerResponse{
      md5_match: true,
      xml_valid: true,
      status_code: 200,
      response_valid: true,
      inserted_at: payload[:event_datetime]
    }
  end
  def server_response_for(payload = %{code: :success}) do
    %ServerResponse{
      md5_match: false,
      xml_valid: true,
      status_code: 200,
      response_valid: true,
      inserted_at: payload[:event_datetime]
    }
  end
end
