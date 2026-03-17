# Something less simple

Let's do something less simple:

```lua
while true do
   print("Meow")
end
```

It indefinitely prints the line "Meow", but not in the speed you would expect. If this was un-sandboxed lua code, it would be freezing the server.

We can even calculate the amount of messages printed per second:

```lua
local t0 = os.clock()
local messages = 0
while true do
   local t = os.clock() - t0
   print(("Printing %s messages per second"):format(messages/t))
   messages = messages + 1
end
```

Because of how the print function behaves, the amount will change if you are looking at the Terminal tab.

<!-- Because it is updating the UI for every print if you are looking at the terminal tab, horrifyingly inefficient -->

## About the limits

When a luacontroller is on, its infotext is "Lag: <some amount>/$lag_per_second_max$ ms".  
Those amounts are the lag produced per second, the second number after the "/" is the limit.

Your luacontroller will temporarily stop if it produces more than $lag_per_second_max$ms of lag in one second.  
(More specifically, it will temporarily stop activating for that second.)

