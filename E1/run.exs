#!/usr/bin/env elixir
# run.exs – run the lexer without compiling a mix project:
#   elixir run.exs sample1.py
#   elixir run.exs sample1.py output.html

Code.require_file("lib/python_lexer.ex", __DIR__)
Code.require_file("lib/cli.ex", __DIR__)

PythonLexer.CLI.main()
