# Writing scripts and extensions
Making script commands that Scarlet can run is very easy, as a DSL was created specifically for this purpose. The bot's commands are defined trough the `Scarlet.hear` block. The way it works is that you put in a regex as the argument, which will match the input string which you want to trigger the command. You don't need to manually set the prefix for the command, as the DSL automatically matches the prefixes `/^#{@current_nick}[:,]?\s*/i` or the control char `!`. (so `/foobar/` will match **Scarlet, foobar** and **!foobar**). Optionally, you can capture sub-strings with the regex which you can then later access in the block.

Inside these blocks, you can use any of server's send commands (msg, notice, send_data, send_cmd) to send messages to the server (and users). You also have full access to `@event`'s variables, which contain the who, what and where of an IRC "event" (in the scope of a hear block it's a private message). Even more, you can and should omit the `@event` and just use the variables directly (i.e. `@event.sender.nick` => `sender.nick`). For further information on these variables, see [Scarlet/lib/event.rb](https://github.com/archSeer/Scarlet/blob/master/lib/event.rb).

### Match captures

`params` is a **MatchData** object. Standard rules for it apply: `params` **and** `params[0]` will return the full string user entered, while `params[n]` will return n-th match capture. If you used named groups, you can access it the same way, by using it's name as a symbol: `params[:named_group]`.

### Returning a message back to sender

`return_path` is a preset for sending a message back where it came from, either a channel or a private message. There is no need to use it directly when sending back a normal message, just use the `reply(message)` command which does it for you (It's an alias for `msg(return_path, message)`).

### Help documentation

The help documentation for the command is written as a comment in the script file itself. It has to be in the format of _example - explanation_.

## Using internet protocols

Scarlet is written using Event Machine, which is asynchronous. That means HTTP requests or other protocols must be done using asynchronous code too. This can either be solved using [gems created specifically for EM](https://github.com/eventmachine/eventmachine/wiki/Protocol-Implementations) or by using `EM.defer` which does lightweight threading with callbacks on completion. [(wiki page)](https://github.com/eventmachine/eventmachine/wiki/EM::Deferrable-and-EM.defer)

### HTTP

HTTP specifically should be done using the em-http-request gem which Scarlet already includes by default. Explanation and examples on it's usage can be found on the [em-http-request wiki](https://github.com/igrigorik/em-http-request/wiki/Issuing-Requests). Be sure to also check out [Scarlet's Google plugin](https://github.com/archSeer/Scarlet/blob/master/commands/google.rb) as an example.

## Simple example:

    # poke <nick> - Sends a notice to <nick>, saying you poked him.
    Scarlet.hear /poke (.+)/, :registered do
       notice params[1], "#{sender.nick} has poked you."
    end
