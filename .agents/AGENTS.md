# Over-Documentation Rule

- **Detailed Docstrings:** Every class and function MUST include a highly detailed docstring explaining its purpose, arguments, return values, and behavior. Lua doesn't have a strict built-in docstring format, so we use standard block comments `---@class` or simple `---` LDoc/EmmyLua style annotations.
- **Line-by-Line Comments:** ALMOST EVERY single line (or logical block) of code must include an inline comment explaining *why* it is there and *how* it works. 
- **Educational Purpose:** The goal is to ensure the user can learn from every single line of code, and that the agent maintains maximum contextual understanding when reading existing files. Do NOT be concise with comments. Over-document everything.
