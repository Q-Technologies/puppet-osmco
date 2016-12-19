#!/bin/bash

subdirs="agent  aggregate  application  data registration  security  util  validator"
plugins="mcollective-service-agent mcollective-puppet-agent mcollective-package-agent mcollective-actionpolicy-auth mcollective-shell-agent/lib/mcollective"

mkdir -p files/plugins
for plugin_dir in $plugins
do
    for subdir in $subdirs
    do
        if [[ -d "$plugin_dir/$subdir" ]]; then
            rsync -a \
                --exclude=".??*" \
                --exclude="*.md" \
                $plugin_dir/$subdir/ \
                files/plugins/$subdir/
        fi
    done
done
rsync -a mcollective-plugins/registration/meta.rb files/plugins/registration/
rsync -a marionette-collective/bin marionette-collective/lib files/
