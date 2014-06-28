defmodule SSDBTest do
  use ExUnit.Case

  setup do 
    {:ok, pid} = SSDB.start
    {:ok, pid: pid}
  end

  test "set", %{pid: pid} do
    {:ok, v} = SSDB.get pid, "a"
    IO.puts v
    assert 1 + 1 == 2
  end
end
