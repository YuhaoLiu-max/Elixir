defmodule PythonLexer.CLI do
  @moduledoc """
  Command-line interface for the Python lexer.

  Usage:
    elixir run.exs <input.py> [output.html]

  If output path is omitted, it defaults to <input_basename>.html
  in the current directory.
  """

  def main(args \\ System.argv()) do
    case args do
      [input | rest] ->
        output = List.first(rest, default_output(input))
        IO.puts("Tokenizing: #{input}")

        case PythonLexer.highlight_file(input, output) do
          :ok ->
            IO.puts("Output written to: #{output}")

          {:error, reason} ->
            IO.puts(:stderr, "Error: #{:file.format_error(reason)}")
            System.halt(1)
        end

      [] ->
        IO.puts(:stderr, "Usage: elixir run.exs <input.py> [output.html]")
        System.halt(1)
    end
  end

  defp default_output(input) do
    base = Path.basename(input, Path.extname(input))
    "#{base}.html"
  end
end
