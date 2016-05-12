defmodule Norta.Feed.Vehicle do
  use Timex
  require Logger

  alias Timex.Format.DateTime.Formatter

  defstruct ~w(route rt_name name lat lng bearing car_type speed gmt time train stale)a

  @field_types %{
    route: String,
    rt_name: String,
    name: Integer,
    lat: Float,
    lng: Float,
    bearing: Float,
    speed: Float,
    car_type: String,
    train: Integer,
    gmt: String
  }

  @stale_time 600 # 10 minutes

  def convert_time(vehicle) do
    if vehicle.gmt do
      reported_local = parse_gmt_time(vehicle.gmt)

      # if it's a future date or diff is larger than the @stale_time
      stale = DateTime.compare(reported_local, DateTime.local) > 0 || DateTime.diff(DateTime.local, reported_local) > @stale_time
      formatted_time = Formatter.format!(reported_local, "{ISO}")

      %{vehicle | stale: stale, time: formatted_time}
    else
      vehicle
    end
  end
  def parse_gmt_time(time) do
    parse_gmt_time(time, String.length(time))
  end
  def parse_gmt_time(time, 5) do
    Logger.debug "5 digit time found: #{time}"
    parse_gmt_time("0" <> time, 6)
  end
  def parse_gmt_time(time, 6) do
    case Regex.run(~r/(\d{2})(\d{2})(\d{2})/, time) do
      [_time, hour, min, sec] ->
        {hour, _} = Integer.parse(hour)
        {min, _} = Integer.parse(min)
        {sec, _} = Integer.parse(sec)

        current_gmt = DateTime.now("Etc/GMT")
        current_local = DateTime.now("America/Chicago")
        reported_gmt = DateTime.set(current_gmt, hour: hour, minute: min, second: sec)

        # This reading may have happened yesterday
        # give ourselves a window of 30 minutes
        if reported_gmt.hour == 23 && current_gmt.hour == 0 && current_gmt.minute < 30 do
          reported_gmt = reported_gmt |> DateTime.shift(days: -1)
        end

        DateTime.local(reported_gmt)
      _ ->
        nil
    end
  end
  def parse_gmt_time(_time, _len) do
    nil
  end

  def convert_coords(vehicle) do
     %{vehicle | lat: norta_dms_to_wgs84(vehicle.lat), lng: norta_dms_to_wgs84(vehicle.lng)}
  end

  def norta_dms_to_wgs84(coord) do
    sign = if coord < 0.0, do: -1.0, else: 1.0
    degrees = Float.floor(abs(coord / 100.0))
    minutes = abs(coord) - (degrees * 100.0)

    sign * (abs(degrees) + (minutes / 60.0))
  end

  def from_map(attr_map) do
    coerced_attrs = attr_map
      |> Enum.map(fn {k, v} -> {k, coerce_attribute(@field_types[k], v)} end)
      |> Enum.into(%{})

    struct(Norta.Feed.Vehicle, coerced_attrs)
  end

  defp coerce_attribute(Integer, val) do
    parse_number(Integer, val)
  end
  defp coerce_attribute(Float, val) do
    parse_number(Float, val)
  end
  defp coerce_attribute(_, v) do
    v
  end

  defp parse_number(_module, nil) do
    nil
  end
  defp parse_number(_module, "") do
    nil
  end
  defp parse_number(module, val) do
    case module.parse(val) do
      {v, _} -> v
      _ -> nil
    end
  end
end
