# osmco
Puppet module to distribute the MCO tools for non-enterprise platforms. E.g. openSUSE, Raspbian

## Instructions
Call the class from your code, e.g. `class { 'osmco': }`

## Issues
This module is using hiera data that is embedded in the module rather than using a params class.  This may not play nicely with other modules using the same technique unless you are using hiera 3.0.6 and above (PE 2015.3.2+).
