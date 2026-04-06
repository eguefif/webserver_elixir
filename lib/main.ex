defmodule Server do
  use Application

  def start(_type, _args) do
    Supervisor.start_link([{Task, fn -> Server.listen() end}], strategy: :one_for_one)
  end

  def listen() do
    # You can use print statements as follows for debugging, they'll be visible when running tests.
    IO.puts("Logs from your program will appear here!")

    {:ok, socket} = :gen_tcp.listen(4221, [:binary, active: false, reuseaddr: true])
    loop_acceptor(socket)
  end

  def loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    serve(client)
    loop_acceptor(socket)
  end

  def serve(socket) do
    request =
      socket
      |> read_line()
      |> parse_request()

    case request.path do
      "/" -> write_line("HTTP/1.1 200 OK\r\n\r\n", socket)
      "/index.html" -> write_line("HTTP/1.1 200 OK\r\n\r\n", socket)
      _ -> write_line("HTTP/1.1 404 Not Found\r\n\r\n", socket)
    end

    :gen_tcp.close(socket)
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
    :gen_tcp.send(socket, line)
  end

  def main(_args) do
    {:ok, _pid} = Application.ensure_all_started(:codecrafters_http_server)
    Process.sleep(:infinity)
  end
end
