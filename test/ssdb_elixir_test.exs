defmodule SSDBTest do
  use ExUnit.Case

  setup do
    {:ok, pid} = SSDB.start
    {:ok, pid: pid}
  end

  test "set and get", %{pid: pid} do
    {:ok, v1} = SSDB.set pid, "a", 3
    assert v1
    {:ok, v2} = SSDB.get pid, "a"
    assert v2 == "3"
  end

  test "get not found", %{pid: pid} do
    {v} = SSDB.get pid, "abcd"
    assert v == :not_found
  end

  test "exists", %{pid: pid} do
    {:ok, v} = SSDB.exists pid, "4345"
    assert !v
  end

  test "del", %{pid: pid} do
    {:ok, true} = SSDB.set pid, "a", 3
    {:ok, true} = SSDB.del pid, "a"
    {:ok, v} = SSDB.exists pid, "a"
    assert !v
  end

end
