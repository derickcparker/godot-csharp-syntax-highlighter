# C# Syntax Highlighter

Adds keyword/type/string/comment/number syntax highlighting for C# scripts
opened in Godot's built-in script editor, which has no C# highlighting
support out of the box.

## Enabling

Go to **Project → Project Settings → Plugins** and enable **C# Syntax
Highlighter**. Then open (or reopen) a `.cs` file in the built-in script
editor.

If a `.cs` file was already open in a tab *before* you enabled the plugin,
Godot won't retroactively apply the new highlighter to that tab — close and
reopen it, or restart the editor.

This only affects Godot's **built-in** script editor. If your Editor
Settings have an external editor configured for C# (VS Code, Rider, Visual
Studio), `.cs` files open there instead and this addon has no effect.

## Limitations

It's a single-pass lexer, not a full C# parser — no semantic analysis (no
Roslyn), so it can't resolve `var` types or distinguish a type name from a
namespace. Type names are guessed by PascalCase convention.

## Full documentation

See the project repository for the full README, a demo file, and source:
https://github.com/derickcparker/godot-csharp-syntax-highlighter

## License

MIT — see [LICENSE](LICENSE).
