defmodule SSDB do

  @type key :: binary | atom
  @type value :: binary | atom | integer


  def start(options \\  []) do
    GenServer.start SSDB.Server, options, []
  end

  def start_link(options \\ []) do
    GenServer.start_link SSDB.Server,  options, []
  end

  def set(pid, key, value) do
    call(pid, ["set", key, value])
  end

  def get(pid, key) do
    call(pid, ["get", key])
  end

  def del(pid, key) do
    call(pid, ["del", key])
  end

  def exists(pid, key) do
    call(pid, ["exists", key])
  end

  def multi_get(pid, keys) do 
    call(pid, ["multi_get" | keys])
  end

  defp call(pid, request) do
    GenServer.call(pid, {:request, request})
  end
end
