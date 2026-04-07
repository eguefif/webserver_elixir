defmodule Server.Acceptor do
  alias Server.Header

  def listen() do
    IO.puts("Logs from your program will appear here!")

    {:ok, socket} = :gen_tcp.listen(4221, [:binary, active: false, reuseaddr: true])
    loop_acceptor(socket)
  end

  def loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(Server.ServerSupervisor, fn -> serve(client) end)
    :ok = :gen_tcp.controlling_process(client, pid)
    loop_acceptor(socket)
  end

  def serve(socket) do
    request =
      socket
      |> read_line()
      |> parse_request()

    case request.path do
      [] ->
        response_200("", socket)

      ["index.html"] ->
        response_200("", socket)

      ["user-agent"] ->
        user_agent = Header.get_header(request, "User-Agent")
        response_200(user_agent, socket)

      ["echo", id] ->
        response_200(id, socket)

      _ ->
        response_404("", socket)
    end

    :gen_tcp.close(socket)
  end

  def response_200(body, socket) do
    "HTTP/1.1 200 OK\r\n"
    |> add_header("Content-Type", "text/plain")
    |> add_header("Content-Length", byte_size(body) |> Integer.to_string())
    |> add_body(body)
    |> write_line(socket)
  end

  def response_404(body, socket) do
    "HTTP/1.1 404 Not Found\r\n"
    |> add_header("Content-Type", "text/plain")
    |> add_header("Content-Length", byte_size(body) |> Integer.to_string())
    |> add_body(body)
    |> write_line(socket)
  end

  def add_header(request, header, content) do
    request <> header <> ": " <> content <> "\r\n"
  end

  def add_body(request, body) do
    request <> "\r\n" <> body
  end

  def read_line(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    data
  end

  def parse_request(request) do
    [header, _rest] = String.split(request, "\r\n\r\n")
    header = Header.get_header(header)
    IO.inspect(header)
    header
  end

  def write_line(line, socket) do
    IO.puts("Sending: " <> line)
    :gen_tcp.send(socket, line)
  end
end
