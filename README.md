Homebrew Helpers
================

A collection of helpers to extend or assist the wonderful Homebrew package manager for macOS/OS X.


Helpers
-------

### `brew-url`

Extends Homebrews list of subcommands. After doing a `brew update` there are often many packages I want to readup on via their website. But using `brew info <package>` and then having to copy & paste the URL into my browser is cumbersom. And as most good developers; I'm sooo lazy. So I created this subcommand so you can now simply `brew url wget` to open up the website for `wget` in Chrome.


### `brewlist`

This simple helper creates the file `brew-list.md` wherever you are in your file system with all the packages currently installed on your system.


### `brewup`

Runs `brew update` and saves the output to a dated logfile in your home directory.


#### `brewup list`

If you run either of `brewup -l`, `brewup last`, or `brewup list` you will get the output of the last logfile created.


Installation
------------

Copy the scripts into your `bin` directory. All commands should work as expected. In the bin directory you can make sure the command is executable with something like `chmod +x brew*` for the current user only. But this may not be necessary. Test with `brew url wget` in Terminal (or iTerm2, etc.) to make sure it's working as expected.

### Example Installation

``` bash
Mac:? runeimp$ cd ~
Mac:~ runeimp$ mkdir repos
Mac:~ runeimp$ cd repos
Mac:repos runeimp$ git clone git@github.com:runeimp/homebrew-helpers.git
Mac:repos runeimp$ cd homebrew-helpers
Mac:homebrew-helpers runeimp$ chmod +x brew*
Mac:homebrew-helpers runeimp$ cd ~/bin
Mac:bin runeimp$ ln -s ../repos/homebrew-helpers/brew-url.sh brewlist
Mac:bin runeimp$ ln -s ../repos/homebrew-helpers/brewlist.sh brewlist
Mac:bin runeimp$ ln -s ../repos/homebrew-helpers/brewup.sh brewlist
Mac:bin runeimp$ cd ~
Mac:~ runeimp$ brew url wget
Mac:~ runeimp$
```


Guarantee
---------

It works on my system. I make no statement of fitness for your usage. It makes me happy. But use at your own risk. :angel:
