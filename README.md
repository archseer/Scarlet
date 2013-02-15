# Scarlet

Scarlet is an IRC bot written in Ruby. It's main purpose is to serve as an IRC bot as well as a personal assistant.

It is designed with multi-channel and multi-server support and offers [a very simple and verbose DSL interface to define new commands](https://github.com/archSeer/Scarlet/wiki/Scripts)

## Installation

```
bundle install --without development
```

## Usage

In order to use Scarlet, you must first create a `config.yml` file. Here is an example of such file:

```yaml
host: GLaDOS
name: Scarlet
quit: Thank you for participating in this Aperture Science computer-aided enrichment activity.
control_char: "!"
display_ping: FALSE
debug: FALSE

servers: {
  server1: {
    address: 'test.irc.net',
    port: 6697,
    ssl: TRUE,
    channels: ['#scarlet', '#bot'],
    nick: "Scarlet",
    password: "password"
  },
  server2: {
    address: 'myirc.irc.net',
    port: 6667,
    channel: ['#irc'],
    control_char: "!",
    nick: 'Scarletto',
  },
}
```

Various IRC networks can be defined in the `servers` hash. Control character can be overriden per-server. If a password is defined, Scarlet will try to login to that server, otherwise if there is no key, it will just skip login. Debug tells Scarlet whether to log all messages to console or only errors and more important messages. 

Afterwards, just run it!

```
ruby core.rb
```

### Creating an owner account

To create an owner account (account having the highest privilege level on the bot), you must first use the `!register` command on one of the channels the Scarlet is in. After successfully registering with the bot, we chdir into the root folder of Scarlet and run the following command:

```
ruby script/owner [USERNAME]
```

Replacing `[USERNAME]` with your username. Scarlet will now recognise you as her owner.

### SSL/TLS

[*SSL/TLS* (Secure Sockets Layer/Transport Layer Security)](http://en.wikipedia.org/wiki/Transport_Layer_Security) is supported. In order to enable it, one must first lookup the port number on which the IRC network accepts SSL/TLS only connections. (Canonically, this port usually is 6697.) The server's config hash in yaml also needs the SSL key set to true:

```yaml
freenode: {
  address: 'wolfe.freenode.net',
  port: 6697,
  ssl: TRUE,
  # ...
}
```

### SASL

In complement to SSL/TLS, [*SASL* (Simple Authentication and Security Layer)](http://en.wikipedia.org/wiki/Simple_Authentication_and_Security_Layer) is also supported. The authentification mechanisms are PLAIN (use only when using SSL/TLS! Sends credentials via cleartext) and DH-BLOWFISH (Diffie-Hellman key exchange with Blowfish encyrption).

```yaml
freenode: {
  # ...
  sasl: TRUE
}
```

### DCC

Scarlet now fully supports DCC SEND for sending and recieving files, as well as [Firewall/Reverse SEND](http://en.wikipedia.org/wiki/Direct_Client-to-Client#Reverse_.2F_Firewall_DCC). There is no RESUME/ACCEPT support yet. This means one could potentially craft a XDCC bot using Scarlet.

### Scarletoids

Scarletoids are Scarlet bots, where the additional commands and responses are written via a DSL directly into the Scarlet object:

```ruby
#!/usr/bin/env ruby
require_relative 'scarlet'
MongoMapper.database = 'scarlet'

module Scarlet
  on :privmsg do |event|
    event.reply 'Oh, a message!'
  end

  ctcp :version do |event|
    notice event.sender.nick "Scarletoid v2"
  end

  hear /test/ do
    reply 'You called !test.'
  end
end

Scarlet.run!
```
