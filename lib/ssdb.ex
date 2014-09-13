defmodule SSDB do

  @type key :: binary | atom
  @type req_type :: binary | atom | integer | list
  @type status :: :ok | :error | :fail | :not_found | :client_error
  @type value :: boolean | list | binary
  @type rsp_type :: {status, value}

  @spec start(Keyword.t) :: GenServer.on_start
  def start(options \\  []) do
    GenServer.start SSDB.Server, options, [name: :ssdb]
  end

  def stop(pid) do
    GenServer.call(pid || client_pid, :stop)
  end

  @spec start_link(Keyword.t) :: GenServer.on_start
  def start_link(options \\ []) do
    GenServer.start_link SSDB.Server,  options, [name: :ssdb]
  end

  @spec set(pid, key, req_type) :: rsp_type
  def set(pid \\ nil, key, value) do
    call(pid, ["set", key, value]) |> bool_reply
  end

  @spec setx(pid, key, req_type, integer) :: rsp_type
  def setx(pid \\ nil, key, value, ttl) do
    call(pid, ["setx", key, value, ttl]) |> bool_reply
  end

  @spec expire(pid, key, integer) :: rsp_type
  def expire(pid \\ nil, key, ttl) do
    call(pid, ["expire", key, ttl]) |> single_reply
  end

  @spec ttl(pid, key) :: rsp_type
  def ttl(pid \\ nil, key) do
    call(pid, ["ttl", key]) |> single_reply
  end

  @spec get(pid, key) :: rsp_type
  def get(pid \\ nil, key) do
    call(pid, ["get", key]) |> single_reply
  end

  def del(pid \\ nil, key) do
    call(pid, ["del", key]) |> bool_reply
  end

  def exists(pid \\ nil, key) do
    call(pid, ["exists", key]) |> bool_reply
  end

  def setnx(pid \\ nil, key, value) do
    call(pid, ["setnx", key, value]) |> bool_reply
  end

  def getset(pid \\ nil, key, value) do
    call(pid, ["getset", key, value]) |> single_reply
  end

  def incr(pid \\ nil, key, num) do
    call(pid, ["incr", key, num]) |> int_reply
  end

  def multi_set(pid \\ nil, kvs) when is_map(kvs) do
    values = Enum.map(kvs, fn({k,v}) -> [k,v] end) |> List.flatten
    call(pid, ["multi_set" | values]) |>  int_reply
  end

  def multi_get(pid \\ nil, keys) when is_list(keys) do
    call(pid, ["multi_get" | keys]) |> kv_reply
  end

  def multi_del(pid \\ nil, keys) when is_list(keys) do
    call(pid, ["multi_del" | keys]) |> int_reply
  end

  # api for hashmap

  def hset(pid \\ nil, name, key, value) do
    call(pid, ["hset", name, key, value]) |> bool_reply
  end

  def hget(pid \\ nil, name, key) do
    call(pid, ["hget", name, key]) |> single_reply
  end

  def hdel(pid \\ nil, name, key) do
    call(pid, ["hdel", name, key]) |> bool_reply
  end

  def hexists(pid \\ nil, name, key) do
    call(pid, ["hexists", name, key]) |> bool_reply
  end

  def hsize(pid \\ nil, name) do
    call(pid, ["hsize", name]) |> int_reply
  end

  def hgetall(pid \\ nil, name) do
    call(pid, ["hgetall", name]) |> kv_reply
  end

  @doc """
  send request to ssdb server, request is a list with command and args
  For example:
      SSDB.call pid, ["set", "a", "1"]

  return values is {status, value}
  """
  @spec call(pid, list) :: {status, list}
  def call(pid, request) when is_list(request) do
    GenServer.call(pid || client_pid, {:request, request})
  end

  @spec int_reply(binary) :: integer
  defp int_reply(response) do
    case response do
      {:ok, values} -> {:ok, String.to_integer(List.first(values))}
      _ -> response
    end
  end

  defp single_reply(response) do
    case response do
      {:ok, values} -> {:ok, List.first(values)}
      _ -> response
    end
  end

  defp bool_reply(response) do
    case response do
      {:ok, values} -> {:ok, List.first(values) == "1"}
      _ -> response
    end
  end

  defp kv_reply(response) do
    case response do
      {:ok, values} -> {:ok, list_to_map(values)}
      _ -> response
    end
  end

  defp list_to_map([]), do: %{}
  defp list_to_map(list) do
    [key, value | rest] = list
    map = Map.put(%{}, key, value)
    Map.merge(map, list_to_map(rest))
  end

  @spec client_pid() :: pid
  defp client_pid do
    Process.whereis(:ssdb)
  end
end
