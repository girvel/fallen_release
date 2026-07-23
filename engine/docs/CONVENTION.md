# Code conventions

## Short ones

1. 2-space indent
2. 100 line width
4. Never use function definition sugar (like `function f() ... end`); instead, always use assignment (like `f = function() end`) -- for search purposes
5. Never indent assignment operator (for search purposes), like in:

```lua
local a   = 1
local bcd = 2
```

6. Function calls always use braces (`()`) except if it's something like `action.plain {...}`, where action.plain is kind of a type

## Underscore fields

Fields, starting with underscore, mean different things for different types of table:

1. When the table is entity, underscore fields mean non-component values i.e. not listed in class
2. When the table is then passed to function-type (like `action.plain` or `cutscene.make`), then underscore mean partial implementations. For example, `:_run` is a partial implementation of `:run`: `cutscene.make` implements `:run` and then calls to `:_run` if provided. So, if you want to rely on `cutscene.make`'s implementation, you provide `:_run`; if you want to reimplement `:run`, you provide it without underscore.
3. In all other tables underscore means private, protected, internal & just overall don't touch
