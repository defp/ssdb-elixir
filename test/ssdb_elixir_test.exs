defmodule SSDBTest do
  use ExUnit.Case, aysnc: false

  setup_all do
    {:ok, _} = SSDB.start
    :ok
  end

  test "query" do
    {:ok, v1} = SSDB.query ["set", "ssdb", "cool"]
    assert v1 == ["1"]

    {:ok, v2} = SSDB.query ["get", "ssdb"]
    assert v2 == ["cool"]

    {:ok, v} = SSDB.query ["del", "ssdb"]
    assert v == ["1"]

    {:ok, v} = SSDB.query ["exists", "ssdb"]
    assert v == ["0"]

    {status, v} = SSDB.query ["get", "abcd"]
    assert status == :not_found
    assert v == []
  end
end
