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
                |> parse_response
                |> reply(state.queue)
    # new_queue = reply(parse(data), state.queue)
    %State{state | queue: new_queue}
  end

  defp reply(value, queue) do
    {{:value, from}, new_queue} = :queue.out(queue)
    :gen_server.reply(from, value)
    new_queue
  end

  defp query(state, from, request) do
    case :gen_tcp.send(state.socket, request) do
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

  defp parse_binary(""), do: []
  defp parse_binary("\n"), do: []

  defp parse_binary(binary) do
    {size, "\n" <> rest} = Integer.parse(binary)
    <<chunk :: [binary, size(size)], "\n", rest :: binary>> = rest
    [chunk|parse_binary(rest)]
  end

  defp parse_response(response) do
    [status | values] = response
    case status do
      "ok" -> {:ok, values}
      "not_found" -> {:not_found, values}
      "error" -> {:error, values}
      "fail" -> {:fail, values}
      "client_error" -> {:client_error, values}
    end
  end
end
