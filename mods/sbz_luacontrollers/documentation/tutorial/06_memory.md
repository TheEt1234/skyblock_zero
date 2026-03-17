# Remembering

By default, the luacontroller doesn't remember anything when it is turned off. Every value gets lost.
<!-- This made me think of a certain dontforget.ogg -->

We can make it remember information, using the `read_mem` and `write_mem` functions:
```lua
local mem = read_mem()
mem.started = (mem.started or -1) + 1
print(("I have been started %s times"):format(mem.started))
write_mem(mem)
```

We can also dump the memory:
```lua
print(dump(read_mem()))
```

And clear it:
```lua
write_mem({})
```

# Limits

The luacontroller memory can only hold $max_memsize_kb$ kilobytes. It uses the luanti function `core.serialize` to serialize it, which is inefficient. So in practice, it's a lot less (especially with binary string data).

Try only writing/reading memory when you need to, it's not fast.

Also try not relying on tables inside themselves (like `t = {}; t.t = t`) or "links" (like `t = {}; t.t1 = {}; t.t2 = t.t1; assert(t.t1 == t.t2)`).
They are supported currently, but might become unsupported in the future, if better methods of serialization become avaliable that don't support this ("links" will just be copies).

The luacontroller memory cannot hold functions, userdata, cdata and threads, it must be serializable.

The luacontroller memory is private, meaning that a local map save cannot see it. But still *DO NOT store passwords or api keys in there, that's a bad idea.*

<!-- Todo: Add a comic where the luacontroller says "Player, i remember you're genocides" lmfao -->
<!-- "player" because i don't want to confirm that the sbz player is human :) /half joking... unless -->
