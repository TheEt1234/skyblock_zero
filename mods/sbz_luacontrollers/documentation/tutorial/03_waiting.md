# Waiting

Let's wait!

```lua
wait(3)
```

That doesn't do anything exciting, but you can notice the luacontroller being on for 3 seconds, then turning off.

Let's do something more interesting.

```lua
print("wait for it")
wait(3)
print("it")
```

The luacontroller prints "wait for it", waits 3 seconds, then prints "it"

We can make a little animation with this.

```lua
local animation = [[|/-\]] -- Using "[[" strings to avoid escaping "\"

while true do
    for i = 1, #animation do
        local char = string.sub(animation, i, i)
        print_clear()
        print(char .. " Loading!")
        wait(0.5)
    end
end
```

(The print_clear function clears the terminal, don't worry we will go over all the functions later)
