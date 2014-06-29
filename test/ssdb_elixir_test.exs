defmodule SSDBTest do
  use ExUnit.Case

  setup do
    {:ok, pid} = SSDB.start
    {:ok, pid: pid}
  end

  test "set get", %{pid: pid} do
    {:ok, v1} = SSDB.set pid, "ssdb", "cool"
    assert v1
    {:ok, v2} = SSDB.get pid, "ssdb"
    assert v2 == "cool"
  end

  test "del", %{pid: pid} do
    {:ok, v} = SSDB.del pid, "ssdb"
    assert v
  end

  test "get not found", %{pid: pid} do
    {v} = SSDB.get pid, "abcd"
    assert v == :not_found
  end

  test "exists", %{pid: pid} do
    {:ok, v} = SSDB.exists pid, "exists"
    assert !v
  end


  test "setnx", %{pid: pid} do
    {:ok, v} = SSDB.setnx pid, "setnx", "test"
    assert v
    {:ok, v} = SSDB.setnx pid, "setnx", "test"
    assert !v
    SSDB.del pid, "setnx"
  end

  test "getset", %{pid: pid} do
    {:ok, true} = SSDB.set pid, "getset", "test"
    {:ok, old} = SSDB.getset pid, "getset", "test1"
    assert old == "test"
    SSDB.del pid, "getset"
  end

  test "incr", %{pid: pid} do
    {:ok, true} = SSDB.set pid, "incr", 1
    {:ok, v} = SSDB.incr pid, "incr", 2
    assert v == "3"
    SSDB.del pid, "incr"
  end

  test "multi_set multi_get multi_del", %{pid: pid} do
    {:ok, num} = SSDB.multi_set pid, %{a: 1, b: 2, c: 3}
    assert num == "3"
    {:ok, map} = SSDB.multi_get pid, ["a", "b", "c"]
    assert map["a"] == "1"
    {:ok, num1} = SSDB.multi_del pid, ["a", "b", "c"]
    assert num1 == "3"
  end
end
