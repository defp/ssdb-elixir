defmodule SSDBTest do
  use ExUnit.Case, aysnc: false

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
    assert v == true
  end

  test "get not found", %{pid: pid} do
    {v, []} = SSDB.get pid, "abcd"
    assert v == :not_found
  end

  test "exists", %{pid: pid} do
    {:ok, v} = SSDB.exists pid, "exists"
    assert v == false
  end

  test "setnx", %{pid: pid} do
    {:ok, v} = SSDB.setnx pid, "setnx", "test"
    assert v == true
    {:ok, v} = SSDB.setnx pid, "setnx", "test"
    assert v == false
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
    assert v == 3
    SSDB.del pid, "incr"
  end

  test "multi_set multi_get multi_del", %{pid: pid} do
    {:ok, num} = SSDB.multi_set pid, %{a: 1, b: 2, c: 3}
    assert num == 3
    {:ok, map} = SSDB.multi_get pid, ["a", "b", "c"]
    assert map["a"] == "1"
    {:ok, num1} = SSDB.multi_del pid, ["a", "b", "c"]
    assert num1 == 3
  end

  test "hset hget hdel", %{pid: pid} do
    {:ok, v1} = SSDB.hset pid, "hset", "k", "vvv"
    assert v1 == true
    {:ok, v2} = SSDB.hget pid, "hset", "k"
    assert v2 == "vvv"
    {:ok, v3} = SSDB.hdel pid, "hset", "k"
    assert v3 == true
  end

  test "hexists", %{pid: pid} do
    {:ok, true} = SSDB.hset pid, "ha", "k", "vvv"
    {:ok, v} = SSDB.hexists pid, "ha", "k"
    assert v
    {:ok, true} = SSDB.hdel pid, "ha", "k"
  end

  test "hsize", %{pid: pid} do
    {:ok, true} = SSDB.hset pid, "ha", "k", "v1"
    {:ok, v} = SSDB.hsize pid, "ha"
    assert v == 1
    {:ok, true} = SSDB.hdel pid, "ha", "k"
  end

  test "hgetall", %{pid: pid} do
    {:ok, true} = SSDB.hset pid, "ha", "k1", "v1"
    {:ok, true} = SSDB.hset pid, "ha", "k2", "v2"
    {:ok, v} =  SSDB.hgetall pid, "ha"
    assert v["k1"] == "v1"
    {:ok, true} = SSDB.hdel pid, "ha", "k1"
    {:ok, true} = SSDB.hdel pid, "ha", "k2"
  end
end
