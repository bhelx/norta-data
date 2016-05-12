defmodule Norta.Feed.VehicleTest do
  use ExUnit.Case, async: true

  alias Norta.Feed.Vehicle

  test "should be able to convert norta dms to wgs84" do
    coord = -9005.305311
    assert Vehicle.norta_dms_to_wgs84(coord) == -90.08842185
    coord = 2955.445186
    assert Vehicle.norta_dms_to_wgs84(coord) == 29.924086433333333
  end
end
