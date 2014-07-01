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

  def stop(pid) do
    GenServer.call(pid, :stop)
  end

  def handle_call({:request, req}, from, state) do
    query(state, from, req)
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end

  def handle_info({:tcp, socket, data}, %State{socket: socket} = state) do
    :ok = :inet.setopts(socket, [{:active, :once}])
    {:noreply, handle_response(data, state)}
  end

  def handle_info({:tcp, socket, _}, %State{socket: our_socket} = state)
    when our_socket != socket do
      {:noreply, state}
  end

  def handle_info({:tcp_error, _socket, _reason}, state) do
    {:noreply, state}
  end

  def handle_info({:tcp_closed, _socket}, %State{queue: queue} = state) do
    reply_all({:error, :tcp_closed}, queue)
    {:stop, :normal, %{state | socket: nil}}
  end

  def terminate(_reason, state) do
    case state.socket do
      nil -> :ok
      socket -> :gen_tcp.close(socket)
    end
  end

  def code_change(_oldvsn, state, _extra) do
    {:ok, state}
  end

  defp handle_response(data, state) do
    new_queue = data
                |> parse_binary
                |> reply(state.queue)
    %State{state | queue: new_queue}
  end

  defp reply(value, queue) do
    {{:value, from}, new_queue} = :queue.out(queue)
    response = ssdb_response(value)
    GenServer.reply(from, response)
    new_queue
  end

  defp reply_all(value, queue) do
    case :queue.peek(queue) do
      :empty -> :ok
      {:value, {from, _}} ->
        GenServer.reply(from, value)
        reply_all(value, :queue.drop(queue))
    end
  end

  defp query(state, from, request) do
    case :gen_tcp.send(state.socket, create_request(request)) do
      :ok ->
        new_queue = :queue.in(from, state.queue)
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

  defp ssdb_response(response) do
    [status | values] = response
    {String.to_atom(status), values}
  end
end
