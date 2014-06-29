defmodule SSDB do

  @type key :: binary | atom
  @type req_value :: binary | atom | integer | list
  @type rsp_value :: binary | boolean | list
  @type reply_state :: :ok | :not_found | :error | :fail | :client_error
  @type return_value :: {reply_state, rsp_value} | {reply_state}


  def start(options \\  []) do
    GenServer.start SSDB.Server, options, []
  end

  def start_link(options \\ []) do
    GenServer.start_link SSDB.Server,  options, []
  end


  @doc """
  For example: 
    {:ok, pid} = SSDB.start
    {:ok, true} = SSDB.set pid, "a", 3
  """
  @spec set(pid, key, req_value) :: return_value
  def set(pid, key, value) do
    call(pid, ["set", key, value])
  end

  @spec setx(pid, key, req_value, integer) :: return_value
  def setx(pid, key, value, ttl) do
    call(pid, ["setx", key, value, ttl])
  end

  @spec expire(pid, key, integer) :: return_value
  def expire(pid, key, ttl) do
    call(pid, ["expire", key, ttl])
  end

  def ttl(pid, key) do 
    call(pid, ["ttl", key])
  end

  @spec get(pid, key) :: return_value
  def get(pid, key) do
    call(pid, ["get", key])
  end

  def del(pid, key) do
    call(pid, ["del", key])
  end

  def exists(pid, key) do
    call(pid, ["exists", key])
  end

  #TODO test
  def multi_get(pid, keys) do 
    call(pid, ["multi_get" | keys])
  end

  defp call(pid, request) do
    GenServer.call(pid, {:request, request})
  end
end
