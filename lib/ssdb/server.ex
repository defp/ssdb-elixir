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

  def handle_call({command, key, value}, from, state) do
    query(state, from, [command, key, value])
  end

  def handle_call({command, key}, from, state) do
    query(state, from, [command, key])
  end

  def handle_info({:tcp, socket, data}, state) do
    :ok = :inet.setopts(socket, [{:active, :once}])
    {:noreply, handle_response(data, state)}
  end

  def handle_info({:tcp_error, _socket, _reason}, state) do
    {:noreply, state}
  end

  defp handle_response(data, state) do
    # parse response
    new_queue = reply(parse(data), state.queue)
    %State{state | queue: new_queue}
  end

  defp parse(data) do
    data
  end

  defp reply(value, queue) do
    {{:value, from}, new_queue} = :queue.out(queue)
    :gen_server.reply(from, value)
    new_queue
  end

  defp query(state, from, request) do
    req_bin = to_binary(request)
    case :gen_tcp.send(state.socket, req_bin) do
      :ok ->
        new_queue = :queue.in(from, state.queue)
        state = %State{state | queue: new_queue}
        {:noreply, state}
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  defp to_binary(args) do
    args_bin = Enum.map(args, fn(arg) -> "#{byte_size(arg)}\n#{arg}\n" end)
    args_bin ++ ["\n"]
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
end
