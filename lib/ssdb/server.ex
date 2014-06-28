defmodule SSDB.Server do
  use GenServer

  defmodule State do
    defstruct host: nil, port: nil, socket: nil, queue: nil
  end

  def default_options do
    [ host: '127.0.0.1', port: 8888 ]
  end

  def init(options) do
    options = Dict.merge(default_options, options)
    state = %State{ host: options[:host], port: options[:port],
      socket: nil, queue: :queue.new}

    case connect(state) do
      {:ok, new_state} ->
        {:ok, new_state}
      {:error, reason} ->
        {:stop, {:connect_error, reason}}
    end
  end

  def handle_call({:request, req}, from, state) do
    query(state, from, req)
  end

  def handle_info({:tcp, socket, data}, state) do
    :ok = :inet.setopts(socket, [{:active, :once}])
    {:noreply, handle_response(data, state)}
  end

  def handle_info({:tcp_error, _socket, _reason}, state) do
    {:noreply, state}
  end

  defp handle_response(data, state) do
    new_queue = data
                |> parse_binary
                |> reply(state.queue)
    %State{state | queue: new_queue}
  end

  defp reply(value, queue) do
    {{:value, {from, command}}, new_queue} = :queue.out(queue)
    response = ssdb_response(value, command)
    :gen_server.reply(from, response)
    new_queue
  end

  defp query(state, from, request) do
    command = List.first(request)
    case :gen_tcp.send(state.socket, create_request(request)) do
      :ok ->
        new_queue = :queue.in({from, command}, state.queue)
        state = %State{state | queue: new_queue}
        {:noreply, state}
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end


  @socket_options [:binary, {:active, :once}, {:packet, :raw}, {:reuseaddr, true}]
  defp connect(state) do
    case :gen_tcp.connect(state.host, state.port, @socket_options) do
      {:ok, socket} ->
        state = %{state | socket: socket}
        {:ok, state}
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp create_request(args) do
    bin = Enum.map(Enum.map(args, fn(arg) -> to_binary(arg) end),
      fn(arg) -> "#{byte_size(arg)}\n#{arg}\n" end)
    bin ++ ["\n"]
  end

  defp to_binary(x) when is_binary(x), do: x
  defp to_binary(x) when is_integer(x), do: Integer.to_string(x)
  defp to_binary(x) when is_atom(x), do: Atom.to_string(x)
  defp to_binary(x) when is_list(x), do: List.to_string(x)

  defp parse_binary(""), do: []
  defp parse_binary("\n"), do: []

  defp parse_binary(binary) do
    {size, "\n" <> rest} = Integer.parse(binary)
    <<chunk :: [binary, size(size)], "\n", rest :: binary>> = rest
    [chunk|parse_binary(rest)]
  end

  defp ssdb_response(response, command) do
    [status | values] = response
    case status do
      "ok" -> {:ok, get_reply(command, values)}
      "not_found" -> {:not_found}
      "error" -> {:error, List.first(values)}
      "fail" -> {:fail, List.first(values)}
      "client_error" -> {:client_error, List.first(values)}
    end
  end

  defp get_reply("zavg", values) do
    List.first(values) |> String.to_float
  end

  @bool_reply ["exists", "hexists", "zexists"]
  @multi_reply ["keys", "zkeys", "hkeys", "hlist", "zlist", "qslice"]
  @multi_bool_reply ["multi_exists", "multi_hexists", "multi_zexists"]
  @kv_reply ["scan","rscan","zscan","zrscan","zrange","zrrange","hscan","hrscan",
    "hgetall","multi_hsize","multi_zsize","multi_get","multi_hget","multi_zget"]
  @single_reply ["get","substr","getset","hget","qget","qfront", "qback",
    "qpop","qpop_front","qpop_back"]
  @false_or_value_reply ["getbit", "setbit", "countbit", "strlen", "set", "setx",
    "setnx", "zset", "hset", "qpush", "qpush_front", "qpush_back", "del", "zdel",
    "hdel", "hsize", "zsize", "qsize", "hclear", "zclear", "qclear", "multi_set",
    "multi_del", "multi_hset", "multi_hdel", "multi_zset", "multi_zdel", "incr",
    "decr", "zincr", "zdecr", "hincr", "hdecr", "zget", "zrank", "zrrank", "zcount",
    "zsum", "zremrangebyrank", "zremrangebyscore"]

  for cmd <- @bool_reply do
    defp get_reply(unquote(cmd), values) do
      List.first(values) == "1"
    end
  end

  for cmd <- @multi_reply do
    defp get_reply(unquote(cmd), values) do
      values
    end
  end

  for cmd <- @multi_bool_reply do
    defp get_reply(unquote(cmd), values) do
      list_to_bool_map(values)
    end
  end

  for cmd <- @kv_reply do
    defp get_reply(unquote(cmd), values) do
      list_to_map(values)
    end
  end

  for cmd <- @single_reply do
    defp get_reply(unquote(cmd), values) do
      List.first(values)
    end
  end

  for cmd <-@false_or_value_reply do
    defp get_reply(unquote(cmd), values) do
      value = List.first(values)
      case value do
        "0" -> false
        _  -> value
      end
    end
  end

  defp list_to_map([]), do: %{}
  defp list_to_map(list) do
    [key, value | rest] = list
    map = Map.put(%{}, key, value)
    Map.merge(map, list_to_map(rest))
  end

  defp list_to_bool_map([]), do: %{}
  defp list_to_bool_map(list) do
    [key, value | rest] = list
    map = Map.put(%{}, key, value == "1")
    Map.merge(map, list_to_map(rest))
  end
end
