# Complexity Analysis Report

**Course:** Implementation of Computational Methods  
**Date:** May 2026  
**Development language:** Elixir  
**Target language:** Python 3  

---

## 1. Token types

I identified 13 token categories for Python:

| Token | Description | Example |
|---|---|---|
| `keyword` | Python reserved words | `def`, `if`, `async` |
| `builtin` | built-in functions and exceptions | `print`, `len`, `ValueError` |
| `string` | single/double/triple quoted strings | `"hi"`, `'''multi'''` |
| `fstring` | f-strings | `f"x={x}"` |
| `number` | integers, floats, hex, octal, binary, complex | `0xFF`, `3.14`, `4j` |
| `comment` | everything after `#` on a line | `# todo` |
| `operator` | arithmetic, comparison, assignment | `+=`, `**`, `:=` |
| `delimiter` | parens, brackets, comma, dot, etc. | `(`, `.` |
| `decorator` | decorator syntax | `@staticmethod` |
| `identifier` | variable/function/class names | `my_var` |
| `whitespace` | spaces and tabs | `    ` |
| `newline` | line breaks | `\n` |
| `unknown` | anything not matched | `$` |

---

## 2. How the tokenizer works

The tokenizer is a recursive function that goes through the input string from left to right. On each call, it tries to match the beginning of the remaining input to a known pattern. When it finds a match, it consumes that token and recurses on the rest.

Order matters a lot. For example, triple-quoted f-strings (`f"""`) have to be tried before regular f-strings (`f"`), and 3-character operators (`//=`) before 2-character ones (`//`) before single-character ones (`/`). Otherwise tokens would get cut off wrong.

For strings, I handle backslash escapes so the scanner doesn't accidentally close a string on `\"`. For numbers, I check for `0x`, `0o`, `0b` prefixes first, then fall back to decimal (which can include a fractional part, exponent, and `j` suffix for complex numbers).

Identifiers are read in full first, then checked against the keyword and builtin sets. That's simpler than trying to match each reserved word separately.

After tokenizing, a second pass groups the token list by lines and builds the HTML table, wrapping each token in a `<span>` with the right CSS class.

---

## 3. Complexity

Let **n** = number of characters in the input file.

### Tokenizer

Every character is visited at most twice: once in the main dispatch, and once inside the helper that consumes the token. No character is ever re-read from the beginning.

- Pattern dispatch: O(1) per token
- Consuming identifiers, whitespace, numbers: O(t) per token, O(n) total
- Consuming strings: O(s) per string, O(n) total
- Operator matching (fixed list of 17): O(1) per token

**Tokenizer total: O(n)**

### HTML renderer

- Grouping tokens into lines: O(k) where k = number of tokens
- Generating `<span>` tags: O(n)
- `escape_html`: O(n)

**Renderer total: O(n)**

### Overall

```
T(n) = O(n) + O(n) = O(n)
```

The program is linear in the size of the input, which is the best you can do for a lexer since you have to read every character at least once. Space complexity is also O(n) for the token list and the HTML output.

When I ran it on the three sample files (~3 KB, 5 KB, 8 KB), the runtime scaled roughly linearly, which matches the analysis. The constant factor is small because Elixir does binary pattern matching natively without a regex engine.

---

## 4. Ethical implications

A few things came to mind while working on this:

**Privacy.** The same tokenization techniques used here also power static analyzers, AI coding assistants, and automated audit tools. When developers upload code to a cloud service, that code can contain sensitive information in comments or string literals (API keys, personal data, proprietary logic). It's not always obvious that this is happening.

**Education access.** Syntax highlighting makes code a lot easier to read, especially for beginners. Open-source tools like this one help make good development environments available to everyone, not just people who can afford commercial IDEs.

**AI and training data.** Large language models that help write code today were trained on tokenized open-source repositories. It's worth thinking about whether the original authors consented to that use, and what responsibilities come with building on their work.

---

## 5. References

- Python docs — Lexical analysis: https://docs.python.org/3/reference/lexical_analysis.html  
- Elixir docs — Binaries and pattern matching: https://hexdocs.pm/elixir/  
- Aho, Lam, Sethi, Ullman — *Compilers: Principles, Techniques, and Tools*, Chapter 3  
