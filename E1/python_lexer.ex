defmodule PythonLexer do
  @moduledoc """
  Lexer for Python source files.
  Reads a .py file, tokenizes it, and writes a highlighted HTML file.

  Token types:
    :keyword     - reserved words (def, if, for, etc.)
    :builtin     - built-in functions and exceptions
    :string      - string literals
    :fstring     - f-strings
    :number      - integers, floats, hex, octal, binary, complex
    :comment     - # to end of line
    :operator    - arithmetic, comparison, assignment operators
    :delimiter   - parens, brackets, commas, dots, etc.
    :decorator   - @something
    :identifier  - variable/function/class names
    :whitespace  - spaces and tabs (kept for indentation)
    :newline     - line breaks
    :unknown     - anything not matched
  """

  @keywords ~w(
    False None True and as assert async await
    break class continue def del elif else except
    finally for from global if import in is lambda
    nonlocal not or pass raise return try while with yield
  )

  @builtins ~w(
    abs aiter all anext any ascii bin bool breakpoint bytearray bytes
    callable chr classmethod compile complex delattr dict dir divmod
    enumerate eval exec filter float format frozenset getattr globals
    hasattr hash help hex id input int isinstance issubclass iter len
    list locals map max memoryview min next object oct open ord pow
    print property range repr reversed round set setattr slice sorted
    staticmethod str sum super tuple type vars zip
    __import__ __name__ __file__ __doc__ __package__ __spec__
    __loader__ __builtins__ __build_class__
    NotImplemented Ellipsis __debug__
    BaseException Exception ArithmeticError BufferError LookupError
    AssertionError AttributeError BlockingIOError BrokenPipeError
    ChildProcessError ConnectionAbortedError ConnectionError
    ConnectionRefusedError ConnectionResetError EOFError EnvironmentError
    FileExistsError FileNotFoundError FloatingPointError GeneratorExit
    IOError ImportError ImportWarning IndentationError IndexError
    InterruptedError IsADirectoryError KeyError KeyboardInterrupt
    MemoryError ModuleNotFoundError NameError NotADirectoryError
    NotImplementedError OSError OverflowError PendingDeprecationWarning
    PermissionError ProcessLookupError RecursionError ReferenceError
    RuntimeError RuntimeWarning StopAsyncIteration StopIteration
    SyntaxError SyntaxWarning SystemError SystemExit TabError TimeoutError
    TypeError UnboundLocalError UnicodeDecodeError UnicodeEncodeError
    UnicodeError UnicodeTranslateError UnicodeWarning UserWarning
    ValueError Warning ZeroDivisionError
  )

  @keyword_set MapSet.new(@keywords)
  @builtin_set MapSet.new(@builtins)

  # read file, tokenize, write HTML
  def highlight_file(input_path, output_path) do
    case File.read(input_path) do
      {:ok, source} ->
        tokens = tokenize(source)
        html   = render_html(tokens, input_path)
        File.write(output_path, html)
      {:error, reason} ->
        {:error, reason}
    end
  end

  def tokenize(source) do
    tokenize_loop(source, [])
  end

  # base case
  defp tokenize_loop("", acc), do: Enum.reverse(acc)

  # comments
  defp tokenize_loop("#" <> rest, acc) do
    {lexeme, remaining} = take_until_newline(rest, "#")
    tokenize_loop(remaining, [{:comment, lexeme} | acc])
  end

  # decorators
  defp tokenize_loop("@" <> rest, acc) do
    {name, remaining} = take_while(rest, &identifier_char?/1)
    tokenize_loop(remaining, [{:decorator, "@" <> name} | acc])
  end

  # triple f-strings before single f-strings
  defp tokenize_loop(<<"f\"\"\"", rest::binary>>, acc) do
    {lexeme, remaining} = take_triple(rest, ~s("""), "f\"\"\"")
    tokenize_loop(remaining, [{:fstring, lexeme} | acc])
  end

  defp tokenize_loop(<<"f'''", rest::binary>>, acc) do
    {lexeme, remaining} = take_triple(rest, "'''", "f'''")
    tokenize_loop(remaining, [{:fstring, lexeme} | acc])
  end

  # single-line f-strings
  defp tokenize_loop(<<"f\"", rest::binary>>, acc) do
    {lexeme, remaining} = take_string(rest, "\"", "f\"")
    tokenize_loop(remaining, [{:fstring, lexeme} | acc])
  end

  defp tokenize_loop(<<"f'", rest::binary>>, acc) do
    {lexeme, remaining} = take_string(rest, "'", "f'")
    tokenize_loop(remaining, [{:fstring, lexeme} | acc])
  end

  # triple strings before regular strings
  defp tokenize_loop(<<"\"\"\"", rest::binary>>, acc) do
    {lexeme, remaining} = take_triple(rest, ~s("""), ~s("""))
    tokenize_loop(remaining, [{:string, lexeme} | acc])
  end

  defp tokenize_loop(<<"'''", rest::binary>>, acc) do
    {lexeme, remaining} = take_triple(rest, "'''", "'''")
    tokenize_loop(remaining, [{:string, lexeme} | acc])
  end

  # regular strings
  defp tokenize_loop("\"" <> rest, acc) do
    {lexeme, remaining} = take_string(rest, "\"", "\"")
    tokenize_loop(remaining, [{:string, lexeme} | acc])
  end

  defp tokenize_loop("'" <> rest, acc) do
    {lexeme, remaining} = take_string(rest, "'", "'")
    tokenize_loop(remaining, [{:string, lexeme} | acc])
  end

  # numbers
  defp tokenize_loop(<<c, _::binary>> = src, acc) when c in ?0..?9 do
    {lexeme, remaining} = take_number(src)
    tokenize_loop(remaining, [{:number, lexeme} | acc])
  end

  # identifiers - then check if keyword or builtin
  defp tokenize_loop(<<c, _::binary>> = src, acc)
       when c in ?a..?z or c in ?A..?Z or c == ?_ do
    {lexeme, remaining} = take_while(src, &identifier_char?/1)
    type =
      cond do
        MapSet.member?(@keyword_set, lexeme) -> :keyword
        MapSet.member?(@builtin_set, lexeme) -> :builtin
        true -> :identifier
      end
    tokenize_loop(remaining, [{type, lexeme} | acc])
  end

  # newlines - \r\n first for Windows
  defp tokenize_loop("\r\n" <> rest, acc),
    do: tokenize_loop(rest, [{:newline, "\r\n"} | acc])

  defp tokenize_loop("\n" <> rest, acc),
    do: tokenize_loop(rest, [{:newline, "\n"} | acc])

  defp tokenize_loop("\r" <> rest, acc),
    do: tokenize_loop(rest, [{:newline, "\r"} | acc])

  # whitespace
  defp tokenize_loop(<<c, _::binary>> = src, acc) when c in [?\s, ?\t] do
    {lexeme, remaining} = take_while(src, &(&1 in [?\s, ?\t]))
    tokenize_loop(remaining, [{:whitespace, lexeme} | acc])
  end

  # operators and delimiters (fallthrough)
  defp tokenize_loop(src, acc) do
    case match_operator(src) do
      {lexeme, remaining} ->
        tokenize_loop(remaining, [{:operator, lexeme} | acc])
      nil ->
        case match_delimiter(src) do
          {lexeme, remaining} ->
            tokenize_loop(remaining, [{:delimiter, lexeme} | acc])
          nil ->
            <<ch, remaining::binary>> = src
            tokenize_loop(remaining, [{:unknown, <<ch>>} | acc])
        end
    end
  end

  # longest match first to avoid e.g. * matching before **
  @operators [
    "//=", "**=", ">>=", "<<=",
    "**", "//", "<<", ">>", "<=", ">=", "==", "!=", "<>",
    "+=", "-=", "*=", "/=", "%=", "&=", "|=", "^=", "->", ":=", "~=",
    "+", "-", "*", "/", "%", "=", "<", ">", "&", "|", "^", "~", "!"
  ]

  defp match_operator(src) do
    Enum.find_value(@operators, fn op ->
      len = byte_size(op)
      if byte_size(src) >= len and binary_part(src, 0, len) == op do
        {op, binary_part(src, len, byte_size(src) - len)}
      end
    end)
  end

  @delimiters ["(", ")", "[", "]", "{", "}", ",", ":", ";", "."]

  defp match_delimiter(<<ch, rest::binary>>) do
    ch_str = <<ch>>
    if ch_str in @delimiters, do: {ch_str, rest}, else: nil
  end

  defp match_delimiter(""), do: nil

  # string helpers - handle backslash escapes so \" doesn't end the string early
  defp take_string(src, quote, prefix), do: do_take_string(src, quote, prefix, "")

  defp do_take_string("", _q, prefix, acc), do: {prefix <> acc, ""}

  defp do_take_string("\\" <> <<c, rest::binary>>, q, prefix, acc),
    do: do_take_string(rest, q, prefix, acc <> "\\" <> <<c>>)

  defp do_take_string(src, q, prefix, acc) do
    qlen = byte_size(q)
    if byte_size(src) >= qlen and binary_part(src, 0, qlen) == q do
      {prefix <> acc <> q, binary_part(src, qlen, byte_size(src) - qlen)}
    else
      <<c, rest::binary>> = src
      do_take_string(rest, q, prefix, acc <> <<c>>)
    end
  end

  defp take_triple(src, close, prefix), do: do_take_triple(src, close, prefix, "")

  defp do_take_triple("", _c, prefix, acc), do: {prefix <> acc, ""}

  defp do_take_triple(src, close, prefix, acc) do
    clen = byte_size(close)
    if byte_size(src) >= clen and binary_part(src, 0, clen) == close do
      {prefix <> acc <> close, binary_part(src, clen, byte_size(src) - clen)}
    else
      <<c, rest::binary>> = src
      do_take_triple(rest, close, prefix, acc <> <<c>>)
    end
  end

  # number helpers - check for 0x/0o/0b prefix first, then fall back to decimal
  defp take_number(src) do
    cond do
      String.starts_with?(src, "0x") or String.starts_with?(src, "0X") ->
        {digits, rest} = take_while(String.slice(src, 2..-1//1), &hex_char?/1)
        {"0x" <> digits, rest}
      String.starts_with?(src, "0o") or String.starts_with?(src, "0O") ->
        {digits, rest} = take_while(String.slice(src, 2..-1//1), &oct_char?/1)
        {"0o" <> digits, rest}
      String.starts_with?(src, "0b") or String.starts_with?(src, "0B") ->
        {digits, rest} = take_while(String.slice(src, 2..-1//1), &bin_char?/1)
        {"0b" <> digits, rest}
      true ->
        take_decimal(src)
    end
  end

  defp take_decimal(src) do
    {int_part, rest1} = take_while(src, &digit_char?/1)

    {frac_part, rest2} =
      case rest1 do
        "." <> after_dot ->
          {frac, r} = take_while(after_dot, &digit_char?/1)
          {"." <> frac, r}
        _ -> {"", rest1}
      end

    {exp_part, rest3} =
      case rest2 do
        <<e, rest_exp::binary>> when e in [?e, ?E] ->
          {sign, after_sign} =
            case rest_exp do
              "+" <> r -> {"+", r}
              "-" <> r -> {"-", r}
              r -> {"", r}
            end
          {exp_digits, r2} = take_while(after_sign, &digit_char?/1)
          {<<e>> <> sign <> exp_digits, r2}
        _ -> {"", rest2}
      end

    {complex_part, rest4} =
      case rest3 do
        "j" <> r -> {"j", r}
        "J" <> r -> {"J", r}
        _ -> {"", rest3}
      end

    {int_part <> frac_part <> exp_part <> complex_part, rest4}
  end

  defp take_while(src, pred), do: do_take_while(src, pred, "")

  defp do_take_while("", _pred, acc), do: {acc, ""}

  defp do_take_while(<<c, rest::binary>>, pred, acc) do
    if pred.(c),
      do: do_take_while(rest, pred, acc <> <<c>>),
      else: {acc, <<c, rest::binary>>}
  end

  defp take_until_newline(src, prefix), do: do_until_nl(src, prefix)

  defp do_until_nl("", acc), do: {acc, ""}
  defp do_until_nl("\n" <> _ = rest, acc), do: {acc, rest}
  defp do_until_nl("\r" <> _ = rest, acc), do: {acc, rest}
  defp do_until_nl(<<c, rest::binary>>, acc), do: do_until_nl(rest, acc <> <<c>>)

  defp identifier_char?(c),
    do: c in ?a..?z or c in ?A..?Z or c in ?0..?9 or c == ?_

  defp digit_char?(c), do: c in ?0..?9
  defp hex_char?(c), do: c in ?0..?9 or c in ?a..?f or c in ?A..?F or c == ?_
  defp oct_char?(c), do: c in ?0..?7 or c == ?_
  defp bin_char?(c), do: c in [?0, ?1, ?_]

  # HTML rendering

  def render_html(tokens, source_path) do
    filename = Path.basename(source_path)
    now = DateTime.utc_now() |> DateTime.to_string()

    """
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      <title>#{escape_html(filename)}</title>
      <link rel="preconnect" href="https://fonts.googleapis.com">
      <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
      <link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;700&family=Syne:wght@700;800&display=swap" rel="stylesheet">
      <style>
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
        :root {
          --bg: #0d0f17; --surface: #13151f; --border: #1e2130;
          --gutter-bg: #10121a; --text: #cdd6f4; --muted: #45475a; --accent: #89b4fa;
          --c-keyword: #cba6f7; --c-builtin: #89dceb; --c-string: #a6e3a1;
          --c-fstring: #94e2d5; --c-number: #fab387; --c-comment: #6c7086;
          --c-operator: #89b4fa; --c-delimiter: #7f849c; --c-identifier: #cdd6f4;
          --c-decorator: #f38ba8; --c-unknown: #f38ba8;
        }
        body {
          background: var(--bg); color: var(--text);
          font-family: 'JetBrains Mono', monospace; font-size: 14px;
          line-height: 1.7; min-height: 100vh; display: flex; flex-direction: column;
        }
        header {
          padding: 28px 40px 22px; border-bottom: 1px solid var(--border);
          display: flex; align-items: baseline; gap: 20px;
        }
        header h1 {
          font-family: 'Syne', sans-serif; font-size: 1.5rem;
          font-weight: 800; letter-spacing: -0.02em; color: #fff;
        }
        .badge {
          font-size: 0.7rem; letter-spacing: 0.12em; text-transform: uppercase;
          padding: 3px 10px; border-radius: 20px; border: 1px solid var(--border);
          color: var(--muted); background: var(--surface);
        }
        .filename { margin-left: auto; color: var(--accent); font-size: 0.85rem; }
        .legend {
          display: flex; flex-wrap: wrap; gap: 8px 18px; padding: 14px 40px;
          border-bottom: 1px solid var(--border); background: var(--surface);
        }
        .legend-item { display: flex; align-items: center; gap: 6px; font-size: 0.72rem; color: var(--muted); }
        .legend-swatch { width: 9px; height: 9px; border-radius: 2px; }
        .code-wrap { flex: 1; overflow: auto; }
        table.code-table { border-collapse: collapse; width: 100%; tab-size: 4; }
        .code-table td { padding: 0; vertical-align: top; white-space: pre; }
        .code-table .ln {
          background: var(--gutter-bg); color: var(--muted); text-align: right;
          padding: 0 18px 0 24px; user-select: none; border-right: 1px solid var(--border);
          min-width: 52px; font-size: 12px; position: sticky; left: 0;
        }
        .code-table .src { padding: 0 32px; }
        .code-table tr:hover .ln { color: var(--text); }
        .code-table tr:hover .src { background: rgba(255,255,255,0.025); }
        .tok-keyword    { color: var(--c-keyword);  font-weight: 700; }
        .tok-builtin    { color: var(--c-builtin); }
        .tok-string     { color: var(--c-string); }
        .tok-fstring    { color: var(--c-fstring); }
        .tok-number     { color: var(--c-number); }
        .tok-comment    { color: var(--c-comment);  font-style: italic; }
        .tok-operator   { color: var(--c-operator); }
        .tok-delimiter  { color: var(--c-delimiter); }
        .tok-identifier { color: var(--c-identifier); }
        .tok-decorator  { color: var(--c-decorator); }
        .tok-unknown    { color: var(--c-unknown);  text-decoration: underline dotted; }
        footer {
          padding: 12px 40px; border-top: 1px solid var(--border);
          background: var(--surface); font-size: 0.72rem; color: var(--muted);
        }
      </style>
    </head>
    <body>
    <header>
      <h1>Python Lexer</h1>
      <span class="badge">Elixir</span>
      <span class="filename">#{escape_html(filename)}</span>
    </header>
    <div class="legend">#{legend_items()}</div>
    <div class="code-wrap">
      <table class="code-table"><tbody>
        #{build_rows(tokens)}
      </tbody></table>
    </div>
    <footer>#{escape_html(filename)} &middot; #{now}</footer>
    </body>
    </html>
    """
  end

  defp build_rows(tokens) do
    {lines, current} =
      Enum.reduce(tokens, {[], []}, fn
        {:newline, _} = t, {lines, cur} -> {lines ++ [cur ++ [t]], []}
        t, {lines, cur} -> {lines, cur ++ [t]}
      end)

    all_lines = if current == [], do: lines, else: lines ++ [current]

    all_lines
    |> Enum.with_index(1)
    |> Enum.map(fn {line_tokens, num} ->
      cells = Enum.map(line_tokens, &token_to_html/1) |> Enum.join()
      "<tr><td class=\"ln\">#{num}</td><td class=\"src\">#{cells}</td></tr>"
    end)
    |> Enum.join("\n")
  end

  defp token_to_html({:whitespace, lx}), do: escape_html(lx)
  defp token_to_html({:newline, _}), do: ""
  defp token_to_html({type, lx}),
    do: ~s(<span class="tok-#{type}">#{escape_html(lx)}</span>)

  defp legend_items do
    [
      {:keyword, "Keyword"}, {:builtin, "Built-in"}, {:string, "String"},
      {:fstring, "f-String"}, {:number, "Number"}, {:comment, "Comment"},
      {:operator, "Operator"}, {:delimiter, "Delimiter"},
      {:identifier, "Identifier"}, {:decorator, "Decorator"}
    ]
    |> Enum.map(fn {type, label} ->
      ~s(<span class="legend-item"><span class="legend-swatch" style="background:var(--c-#{type})"></span>#{label}</span>)
    end)
    |> Enum.join("\n")
  end

  defp escape_html(str) do
    str
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
  end
end
