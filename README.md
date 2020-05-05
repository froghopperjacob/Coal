<h1 align="center">Coal</h1>
<div align="center">
	<a href="https://github.com/froghopperjacob/Coal/tree/master/LICENSE">
		<img src="https://img.shields.io/badge/License-GNU%203.0-brightgreen.svg?style=flat-square" alt="Lisence" />
	</a>
	<a href="https://github.com/froghopperjacob/Coal/releases">
		<img src="https://img.shields.io/github/v/release/froghopperjacob/Coal?include_prereleases&style=flat-square" alt="Release" />
	</a>
</div>

<div align="center">
	Coal is a small language built in lua with a full Lexer, Parser, and Interpreter. The language was created for fun and mimics Javascript currently but is imagined to be a cross between C#/Java and Lua.
</div>

## Install
1. Head to the most recent release
2. Download and open the Coal.rbxmx file in Roblox Studio
3. Start coding!

## Usage

### CoalModule

```
local Coal = require(Coal)(options)
```

Calling the ``Coal`` function allows a ``Scope`` table

### Coal:interpret

```
local data = Coal:interpret(code)
```

``interpret`` will return ``data`` with the table listed below

### data.tokens

``data.tokens`` holds the code ``tokens`` that are handed to the ``Parser``

### data.AST

``data.AST`` is the Abstract Syntax Tree created by the ``Parser``

### data.globalScope

``data.globalScope`` is the Global scope of the code (``data.scopes["GLOBAL"]`` shorthand)

### data.scopes

``data.scopes`` carries all scopes

### data.times

``data.times`` has the Lexer, Parser, and Interpreter time starts, ends, and elapsed
