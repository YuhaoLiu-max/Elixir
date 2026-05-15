defmodule PythonLexer.MixProject do
  use Mix.Project

  def project do
    [
      app: :python_lexer,
      version: "1.0.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [main_module: PythonLexer.CLI]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps, do: []
end
