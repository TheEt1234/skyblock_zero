# Outside Input

This is the part where we can start to do stuff!
Luacontrollers get output from the outside world using **events**.

An event is a message sent to the luacontroller from the outside world, or from itself.
<!-- When an event gets sent, it usually activates a luacontroller, i will talk about that in later pages -->

Let's try catching one:
```lua
event = get_event()
print(dump(event))
```

We see:
```
{
	["type"] = "program",
}
```

Let's try catching some more

```lua
while true do
    event = get_event()
    print(dump(event))
end
```

We see a few very noisy events that we don't care much about (the "subtick" and "tick" events are sent every 0.25 seconds), let's filter them out.

```lua
while true do
    event = get_event()
    if event.type ~= "subtick" and event.type ~= "tick" then
        print(dump(event))
    end
end
```

We only see the program event, but if we type `something` into the terminal, we can see a `terminal` event:
```
{
	["msg"] = "something",
	["type"] = "terminal",
}
```

Let's try using that:

```lua
while true do
    event = get_event()
    if event.type == "terminal" then
        print("We received: " .. event.msg)
    end
end
```

We can even make a tiny REPL:
```lua
local function eval(code)
    local f, errmsg = loadstring(code)
    if not f then print(dump(errmsg)) return end -- the syntax errors usually aren't a string, we will get to this later
    local ok, errmsg = pcall(f)
    if not ok then print(dump(errmsg)) return end
end

while true do
    event = get_event()
    if event.type == "terminal" then
        eval(event.msg)
    end
end
```

If we send `print("Hello world")` to the terminal, it will print hello world.
You will have to make your own fancy view for syntax errors, or just rely on the table dump.

Yey! We can now receive from the terminal! But what about other things? What about requesting information?
We will get there.
