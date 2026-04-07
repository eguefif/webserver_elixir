defmodule Server.Response do
  def response_200(socket, body, content_type \\ "text/plain") do
    "HTTP/1.1 200 OK\r\n"
    |> add_header("Content-Type", content_type)
    |> add_header("Content-Length", byte_size(body) |> Integer.to_string())
    |> add_body(body)
    |> write_line(socket)
  end

  def response_404(socket) do
    "HTTP/1.1 404 Not Found\r\n\r\n"
    |> write_line(socket)
  end

  def add_header(request, header, content) do
    request <> header <> ": " <> content <> "\r\n"
  end

  def add_body(request, body) do
    request <> "\r\n" <> body
  end

  def write_line(line, socket) do
    IO.puts("Sending: " <> line)
    :gen_tcp.send(socket, line)
  end
end
