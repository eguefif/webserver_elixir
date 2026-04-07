defmodule Server.Response do
  def response_200(socket, body, request, content_type \\ "text/plain")

  def response_200(socket, "", request, _content_type) do
    "HTTP/1.1 200 OK\r\n"
    |> add_encoding(request)
    |> add_body("")
    |> write_line(socket)
  end

  def response_200(socket, body, request, content_type) do
    "HTTP/1.1 200 OK\r\n"
    |> add_header("Content-Type", content_type)
    |> add_encoding(request)
    |> add_body(body)
    |> write_line(socket)
  end

  def response_201(socket) do
    "HTTP/1.1 201 Created\r\n\r\n"
    |> write_line(socket)
  end

  def response_404(socket) do
    "HTTP/1.1 404 Not Found\r\n\r\n"
    |> write_line(socket)
  end

  def add_header(response, header, content) do
    response <> header <> ": " <> content <> "\r\n"
  end

  def add_body(response, body) do
    body =
      case String.contains?(response, "gzip") do
        true -> Server.Gzip.encode(body)
        false -> body
      end

    response = add_header(response, "Content-Length", byte_size(body) |> Integer.to_string())

    response <> "\r\n" <> body
  end

  def write_line(line, socket) do
    :gen_tcp.send(socket, line)
  end

  def add_encoding(response, request) do
    case Server.Header.get_header(request, "Accept-Encoding") do
      "" ->
        response

      encoding ->
        algorithms =
          String.split(encoding, ",", trim: true)
          |> Enum.map(fn entry -> String.downcase(String.trim(entry)) end)

        case Enum.any?(algorithms, fn algo -> algo == "gzip" end) do
          true -> add_header(response, "Content-Encoding", "gzip")
          false -> response
        end
    end
  end
end
