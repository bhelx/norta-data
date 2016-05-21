defmodule Norta.ServerResponseTest do
  use Norta.ModelCase

  alias Norta.ServerResponse

  @valid_attrs %{status_code: 42}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = ServerResponse.changeset(%ServerResponse{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = ServerResponse.changeset(%ServerResponse{}, @invalid_attrs)
    refute changeset.valid?
  end
end
