Homebrew Helpers v0.6.0
=======================

A collection of helpers to extend or assist the wonderful Homebrew package manager for macOS/OS X.


Helpers
-------

### `brew-url`

Extends Homebrews list of subcommands. After doing a `brew update` there are often many packages I want to readup on via their website. But using `brew info <package>` and then having to copy & paste the URL into my browser is cumbersom. And as most good developers; I'm sooo lazy. So I created this subcommand so you can now simply `brew url wget` to open up the website for `wget` in your default browser.

The default browser is either the config variable `browser`, the environment variable `BROWSER_NAME`, or OS default (Safari).

Config checking now looks for either `${XDG_CONFIG_HOME}/brew-url` or `${HOME}/.brew-url` so you can set the script variable `browser` to the app name of the browser you wish `brew-url` to use as it's default.

The config variable `browser` takes precedence over the environment variable `BROWSER_NAME`. And the environment variable takes precedence over the OS default.


#### `brew url -c <package>`

Also `brew url --chrome <package>`. Specifies to use _Google Chrome_ instead of the default browser to review the packages website.


#### `brew url -d <package>`

Also `brew url --default <package>`. Specifies to use the default OS browser (typically _Safari_) to review the packages website.


#### `brew url -f <package>`

Also `brew url --firefox <package>`. Specifies to use _Firefox_ instead of the default browser to review the packages website.


#### `brew url -o <package>`

Also `brew url --opera <package>`. Specifies to use _Opera_ instead of the default browser to review the packages website.


#### `brew url -s <package>`

Also `brew url --safari <package>`. Specifies to use _Safari_ instead of the default browser to review the packages website.


#### `brew url -v`

Also `brew url --version` can be used to display the version of `brew-url`.


### `brewlist`

This simple helper creates the file `${USER}-brew-list_YYYY-MM-DD_HHMMSS.md` wherever you are in your file system with all the packages currently installed on your system.


#### `brewlist -e <file_extension>`

Also `brewlist --ext` and `brewlist --extension` can be used to specify a different file extension than `.md`.


#### `brewlist -f <base_filename>`

Also `brewlist --file` can be used to specify the base filename instead of `${USER}-brew-list`.


#### `brewlist -p <prefix>`

Also `brewlist --prefix` can be used to specify a prefix to prepend to the base filename.


#### `brewlist -s <suffix>`

Also `brewlist --suffix` can be used to specify a suffix to append to the base filename prior to the file extension.


#### `brewlist -V`

Also `brewlist --version` can be used to display the version of `brewlist`.


### BrewUp

See [brewup.md](brewup.md)



Installation
------------

Copy or symlink the scripts into your prefered `bin` directory. All commands should work as expected. In the bin directory you can make sure the command is executable with something like `chmod +x brew*` for the current user only. But this may not be necessary. Test with `brew url wget` in Terminal (or iTerm2, etc.) to make sure it's working as expected.

### Example Installation

``` bash
Mac:? runeimp$ cd ~
Mac:~ runeimp$ mkdir repos
Mac:~ runeimp$ cd repos
Mac:repos runeimp$ git clone git@github.com:runeimp/homebrew-helpers.git
Mac:repos runeimp$ cd homebrew-helpers
Mac:homebrew-helpers runeimp$ chmod +x brew*
Mac:homebrew-helpers runeimp$ cd ~/bin
Mac:bin runeimp$ ln -s ../repos/homebrew-helpers/brew-url.bash brew-url
Mac:bin runeimp$ ln -s ../repos/homebrew-helpers/brewlist.bash brewlist
Mac:bin runeimp$ ln -s ../repos/homebrew-helpers/brewup.bash brewup
Mac:bin runeimp$ cd ~
Mac:~ runeimp$ brew url wget
Mac:~ runeimp$
```

#### IMPORTANT

The process outlined above has been updates since the last release. A few of the scripts have had their `.sh` file extensions changed to `.bash`. If you've set this up in the past as noted prior then you will need to relink to the scripts with new file extensions. I apologize for any inconvenience. :angel:


Guarantee
---------

It works on my system. I make no statement of fitness for your usage. It makes me happy. Use at your own risk. :angel:

