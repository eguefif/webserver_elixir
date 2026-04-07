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
    with {:ok, data} <- read_line(socket),
         [header, body] <-
           parse_request(data) do
      dispatch_request(socket, header, body)

      case Server.Header.get_header(header, "Connection") do
        "close" -> :gen_tcp.close(socket)
        _ -> serve(socket)
      end
    else
      _ -> :gen_tcp.close(socket)
    end
  end

  def dispatch_request(socket, header, body) do
    case {header.method, header.path} do
      {:get, []} ->
        Server.Response.response_200(socket, "", header)

      {:get, ["files" | path]} ->
        Server.Files.response_files(socket, path, header)

      {:post, ["files" | path]} ->
        Server.Files.create_file(socket, path, body, header)

      {:get, ["index.html"]} ->
        Server.Response.response_200(socket, "", header)

      {:get, ["user-agent"]} ->
        user_agent = Header.get_header(header, "User-Agent")
        Server.Response.response_200(socket, user_agent, header)

      {:get, ["echo", id]} ->
        Server.Response.response_200(socket, id, header)

      {_, _} ->
        Server.Response.response_404(socket)
    end
  end

  def read_line(socket) do
    :gen_tcp.recv(socket, 0)
  end

  def parse_request(request) do
    [header, body] = String.split(request, "\r\n\r\n")
    header = Header.get_header(header)
    [header, body]
  end
end
