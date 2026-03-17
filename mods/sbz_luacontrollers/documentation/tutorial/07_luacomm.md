# Communication

Luacomm (stands for luacontroller communication) is how a luacontroller communicates with other nodes.

To use it, first craft the luacontroller linker tool (technically not required but it would be a lot less convenient)
<!-- This is technically possible without it. But would be a lot less convenient. -->

Let's try making two luacontrollers communicate.

1) Place the first luacontroller, this one will be sending messages
2) Punch the luacontroller with the linker tool, this will link that luacontroller with the tool
3) Place the second luacontroller, this one will be receiving messages
4) Right-click on the second luacontroller with the linker tool (make sure the tool is linked with the first luacontroller), and pick a name, i chose `receiver` here, the name matters because it's what the `links` table contains.

5) Enter the code:
```lua
luacomm_send(links.receiver, "Meow")
```
into the first luacontroller, the one that will be sending the messages

6) Enter the code:
```lua
while true do
    local e = get_event()
    if e.type == 'luacomm' then
        print(("Received message: %s"):format(e.msg))
    end
end
```
into the 2nd luacontroller, the one that will be receiving messages

To run it, first turn on the 2nd luacontroller (the receiver), then turn on the 1st luacontroller (the sender).

On the 2nd luacontroller you will see: `Received message: Meow`

You can turn on the 1st luacontroller as many times as you'd like, and you will see multiple messages. 

*But this is not the proper way to receive messages*, because if there was more than one luacontroller sending messages, it would be impossible to tell them apart.

So let's do it properly.

7) Link the luacontroller that is receiving the messages with the luacontroller that is sending them, give the link the name `sender`
- You do this by punching the luacontroller that is receiving with the linking tool, then making a link like last time

8) Replace the code in the luacontroller that is receiving the messages with:
```lua
while true do
    local e = get_event()
    if e.type == 'luacomm' and vector.equals(e.from_pos, links.sender) then
        print(("Received message: %s"):format(e.msg))
    end
end
```

With this, we can also communicate with multiple luacontrollers and distinguish between them, but that is an excercise for the viewer.
You can also communicate in both ways, that's also an excercise for the viewer.

# Limits

A luacomm message must not have userdata, threads, cdata or functions.

A luacomm message must be below $max_luacomm_message_length$ kilobytes.
