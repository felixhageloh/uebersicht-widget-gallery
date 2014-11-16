# Übersicht widget gallery

Includes the build script, widget repos and the website repo

## Setup

You need NodeJs installed on your system. For OS X use:

    brew install node

In case you don't have homebrew yet, you can [get it here](http://brew.sh).
After you installed NodeJS, install coffee script:

    npm install -g coffee-script

that should be it.

## General layout

The build script looks at several repos, refreshes them and spits out a `widgets.json` file that contains a list of all widgets it found. The widget.json file is then used by the website to render the widget list.

The main repo is `uebersicht-widgets` to which widgets are added as git submodules. There are a few other repos which are managed by others.

The website can be found inside `website` and it is actually the gh-pages branch of the `uebersicht-widgets` repo, added as a seperate folder for convenience.

## Adding widgets

People will open an Issue with the repo url of their widget. With the url do

    cd uebersicht-widgets
    git submodule add <widget-repo-url> <local-folder-name>
    git commit -m 'Added <name of widget>'
    cd ..

Commonly people call their repo something like 'ubersicht-xyz-widget' so I then set `<local-folder-name>` to just 'xyz-widget'. If you don't provide one, the name of the repo will be used.

The next step is to execute the build script

    ./build.coffee

It will give some output on which widets are added and if something went wrong. It should give a quite clear indication what is missing in case the new widget breaks (widget.json file is broken, no screenshpt found etc.)

In case everything goes fine, the next step is to copy the newly created widget.json file to the website:

    mv widget.json website/
    cd website
    git add widget.json
    git commit -m 'Added <name of widget>'
    git push

Git push will put the new changes live - you should be able to see them almost immediately. Before I do that I usally start the website to double check locally. For that I use `nws` (`npm install -g nws` to install). Inside the website folder, after copying the widget.json over do:

    nws

and then open the site on `http://localhost:3030`

After you deployed the site, make sure to also push the changes to the widget repo:

    cd uebersicht-widgets
    git push

On the other hand, if something goes wrong (build script fails), just disgard the widget.json file and undo adding the submodule:

    cd uebersicht-widgets
    git reset --hard HEAD~1

No need to push anything in this case.
