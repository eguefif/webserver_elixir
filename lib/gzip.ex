defmodule Server.Gzip do
  def encode(body) do
    result = :zlib.gzip(body)
    result
  end
end
