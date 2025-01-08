# JJscript
> a bs programming language, built for the purpose of building a programming language (and learning how to)

## "Features"

### environments
- variables designed outside of functions are considered global
- local environments using `{ ... }`
- functions using `id = { ... }` or `id = {(ARGS) ... }`

### Variables
- dynamically typed: `x = 1.3; x = "abc";`
- dynamically named: `x${x} = true; printl(xabc)`

#### datatypes
- integer (Hex values using 0x...)
- float
- string
- NONE
- bool ("true"|"false")
- lists using \[\]
