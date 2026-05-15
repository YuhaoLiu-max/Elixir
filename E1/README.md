# Python Lexer in Elixir

This program reads a Python source file and outputs an HTML file with syntax highlighting.

## How to run

```bash
elixir run.exs samples/sample1.py
# outputs sample1.html in the current directory

elixir run.exs myfile.py output.html
```

You need Elixir installed: https://elixir-lang.org/install.html

## Project structure

```
├── lib/
│   ├── python_lexer.ex   <- main lexer
│   └── cli.ex            <- CLI entry point
├── samples/
│   ├── sample1.py / .html
│   ├── sample2.py / .html
│   └── sample3.py / .html
├── run.exs
├── mix.exs
└── REPORT.md
```

## Token types

| Token | Color | Examples |
|---|---|---|
| keyword | purple | `def`, `if`, `for`, `True` |
| builtin | sky | `print`, `len`, `range` |
| string | green | `"hello"`, `'''multi'''` |
| fstring | teal | `f"x={x}"` |
| number | orange | `42`, `3.14`, `0xFF`, `4j` |
| comment | grey | `# comment` |
| operator | blue | `+=`, `**`, `:=` |
| delimiter | light grey | `(`, `[`, `.` |
| identifier | white | `my_var`, `MyClass` |
| decorator | red | `@staticmethod` |
