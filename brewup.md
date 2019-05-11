BrewUp
======

This is a tool I use to handle updates, upgrades, cleanup and view my installed package list.


Rational
--------

Homebrew's `brew` command is pretty awesome all by itself. But I find in my normal usage some usability issues:

1. When I `brew update` I like to keep the list handy to review. But if I clear the terminal buffer (I do so often) then there is no way (that I know of) to get the list of updated packages. That is probably just me not searching the help system. But I also like logging this activity.
2. I like to run `brew upgrade --cleanup`. But this has often proven buggy so have to use `brew cleanup` after `brew upgrade`. Which usually works just fine. But I didn't realize it until it was too late but cleanup _whole saled_ (deleted) all prior minor versions. Something I didn't think mattered much to me until the upgrade for Python 3.7 came through. Upon `cleanup` I found my Python 3.6.5 was blown away. Plus I discovered that I couldn't just do something like `brew install python@3.6` and have it reinstall that version. The Homebrew system does not automatically make older versions of packages available. That is done manually by package maintainers for some packages. Luckily the ability to install packages by version is being considered. But is not yet available as of this writing.

So I wrote `brewup` originally to support the first issue. But the most reacent update also fixes the second issue.


Features
--------

### `brewup`

Runs `brew update` and saves the output to a dated logfile in your brewup directory which will be one of the following.

- `$XDG_CONFIG_HOME/brewup`
- `$HOME/.local/brewup`
- `$HOME/.brewup`

if `XDG_CONFIG_HOME` is defined then <code>$XDG_CONFIG_HOME/brewup</code> will be created. If not and <code>$HOME/.local</code> exists then <code>$HOME/.local/brewup</code> will be created. Else `$HOME/.brewup` will be created.


### `brewup list`

If you run either of `brewup -l`, `brewup last`, or `brewup list` you will get the output of the last logfile created.


### `brewup upgrade` (with smart cleanup)

1. Run `brew upgrade`
2. Run BrewUp's _smart cleanup_ function.


### `brewup cleanup` (_smart cleanup_)

* Based on the retain level used smart cleanup will keep/retain the latest version of each package at that level and higher. And remove everything else.
* By default the cleanup retain level is set to minor.


#### Smart Cleanup Example

If retain is at the default level of _minor_ and I have in my list of packages `bash 3.2.57, 4.3.1, 4.4.21, 4.4.23, 5.0.0` smart cleanup will kill (remove, delete, etc.) `4.4.21` and keep (leave alone) `3.2.57`, `4.3.1`, `4.4.23`, and `5.0.0`. If the retain level is set to _major_ (`brewup upgrade -r major` for instance) then smart cleanup would kill `4.3.1`, and `4.4.21` and keep `3.2.57`, `4.4.23`, and `5.0.0`


TODO
----

In no particular order:

- [ ] Automatically archive (gzip) older logs to save space. Always gzip?
- [ ] Automatically delete logs after a certain amount of time weather they are archived or not. User defined time.
- [ ] Interactive mode. Ask before removing any packages during cleanup, etc.
- [ ] Make smart cleanup not autostart after `upgrade`. Which will make the options `-c`, `-clean`, `--cleanup` and the `cleanup` command more useful.
- [ ] Specify different cleanup retain level for different packages in a config file.


Fitness for Use
---------------

I give no garauntees for this scripts fitness for use on any specific computer. I suspect it is "safe enough" to not mangle any untested systems. I've only used this on my own iMac with macOS Majave on it. Do not blame me if you try this and your system suffers for it. I share this code with the world so as to be easy for me to reference personally and in the hope that others will find it useful as well.

