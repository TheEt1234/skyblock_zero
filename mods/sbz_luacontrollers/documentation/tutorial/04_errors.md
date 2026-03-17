# Errors

There are two kinds of errors

## Syntax errors

These errors occur before the code runs.

The code:
```lua
print("Hello world!
```

Will produce these syntax errors:

```
[error] > print("Hello world!
[error]         ^
[error] main:7:1: malformed string
[error]  
[error] > print("Hello world!
[error]                      ^
[error] main:20:1: syntax error, expected one of: ')', ','
[error]  
```

They are different from regular syntax errors because luacontroller code is first processed by a tool.

<!-- By a tool i meant a transpiler! You are not writing lua code, you are writing teal code. -->
<!-- These aren't *lua*controllers. They don't directly run lua. -->
<!-- The teal language is a superset of lua, so all lua code is valid teal code. -->
<!-- But if you want types they are there i guess. They won't do anything. -->

**To avoid losing your changes and have automatic syntax checking, you should use an external code editor, and paste the code from it to the luacontroller.**

Luanti's limitations don't allow creating a good code editor. I would love to be proven wrong.

## "Runtime" (Regular) errors

These errors happen at *runtime*, when the luacontroller is running.

```lua
print("a")
error("Hello world")
print("b")
```

Will output:
```
a
[error] [string "main"]:2: Hello world
```


In this case, the syntax of the code is correct, but the call to the `error` function will cause an error once the interpreter reaches it.

Some functions will also throw an error if you put incorrect values into them.

<!-- Yes interpreter, there is no way this could be JIT compiled, and error is NYI in luaJIT anyway -->

These errors can be caught with `pcall` and `xpcall`.

`xpcall` can provide extra information about the error, like a traceback:

```lua
local ok, errmsg = xpcall(function()
    function a()
        error("a")
    end
    a()
end, debug.traceback)

print(ok)
print(errmsg)
```

can output:

```
false
[string "main"]:3: a
stack traceback:
	~/.minetest/games/skyblock_zero/mods/slua/env.lua:66: in function <~/.minetest/games/skyblock_zero/mods/slua/env.lua:64>
	[C]: in function 'error'
	[string "main"]:3: in function 'a'
	[string "main"]:5: in function <[string "main"]:1>
	[C]: in function 'f'
	~/.minetest/games/skyblock_zero/mods/slua/env.lua:66: in function 'xpcall'
	[string "main"]:1: in main chunk
```

<!-- No it can't, i replaced the "/home/my_user" with "~/"-->


