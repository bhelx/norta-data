defmodule Norta.Feed.Parser do
  use Timex
  require Logger

  alias Timex.Format.DateTime.Formatter
  alias Norta.Feed.XmlNode

  def parse_vehicles(xml_string) do
    doc = Norta.Feed.XmlNode.from_string(xml_string)

    doc
    |> XmlNode.all("//unit")
    |> Enum.map(&parse_vehicle(&1))
  end

  def parse_vehicle(xml_node) do
    attributes = ~w(route rt_name name lat lng bearing car_type speed GMT train)
      |> Enum.reduce([], fn(attr, attrs) -> [parse_vehicle_attribute(attr, xml_node) | attrs] end)
      |> Enum.into(%{})

    attributes |> coerce |> convert_coords |> convert_time
  end

  defp parse_vehicle_attribute(attribute, xml_node) do
    val = xml_node |> XmlNode.first("//#{attribute}") |> XmlNode.text

    {normalize_key(attribute), normalize_value(val)}
  end

  defp normalize_key(key) do
    key |> String.downcase |> String.to_atom
  end

  defp normalize_value(val) when is_binary(val) do
    Regex.replace(~r/\'/, val, "")
  end
  defp normalize_value(val) do
    val
  end

  def coerce(vehicle_map) do
    vehicle_map
    |> Map.update(:bearing, 0.0, fn bearing ->
      {v, _} = Float.parse(bearing)
      v
    end)
    |> Map.update(:speed, 0.0, fn speed ->
      {v, _} = Float.parse(speed)
      v
    end)
  end

  def convert_time(vehicle_map) do
    if vehicle_map[:gmt] do
      reported_gmt = parse_gmt_time(vehicle_map[:gmt])

      if reported_gmt do
        reported_local = DateTime.local(reported_gmt)

        # if it's a future date or diff is larger than the @stale_time
        stale = DateTime.compare(reported_local, DateTime.local) > 0 || DateTime.diff(DateTime.local, reported_local) > @stale_time
        formatter = Timex.Format.DateTime.Formatters.Strftime

        formatted_time = formatter.format!(reported_gmt, "%Y-%m-%d %H:%M:%S")

        vehicle_map
        |> Map.put(:stale, stale)
        |> Map.put(:reading_time, formatted_time)
      else
        vehicle_map
      end
    else
      vehicle_map
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

        reported_gmt
      _ ->
        nil
    end
  end
  def parse_gmt_time(_time, _len) do
    nil
  end

  def convert_coords(vehicle_map) do
    %{vehicle_map | lat: norta_dms_to_wgs84(vehicle_map[:lat]), lng: norta_dms_to_wgs84(vehicle_map[:lng])}
  end

  def norta_dms_to_wgs84(coord) do
    {coord, _} = Float.parse(coord)

    sign = if coord < 0.0, do: -1.0, else: 1.0
    degrees = Float.floor(abs(coord / 100.0))
    minutes = abs(coord) - (degrees * 100.0)

    sign * (abs(degrees) + (minutes / 60.0))
  end
end
