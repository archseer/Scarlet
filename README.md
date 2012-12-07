# Scarlet

Scarlet is an IRC bot written in Ruby. It's main purpose is to serve as an IRC bot as well as a personal assistant.

It is designed with multi-channel and multi-server support and offers [a very simple and verbose DSL interface to define new commands] (https://github.com/archSeer/Scarlet/wiki/Scripts)

## Usage

In order to use Scarlet, you must first create a `config.yml` file. Here is an example of such file:

    host: GLaDOS
    name: Scarlet
    quit: Thank you for participating in this Aperture Science computer-aided enrichment activity.
    control_char: "!"
    display_ping: FALSE
    relay: FALSE
    debug: FALSE

    servers: {
      server1: {
        address: 'test.irc.net',
        port: 6667,
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

Various IRC networks can be defined in the `servers` hash. Control character can be overriden per-server. If a password is defined, Scarlet will try to login to that server, otherwise if there is no key, it will just skip login. Debug tells Scarlet whether to log all messages to console or only errors and more important messages. 