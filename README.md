# Cap::Docker

This project aims to make it simple to deploy an app inside Docker containers.

## Concept

You have a host and you set up a docker baseimage like this one. Once you have the basimage you are ready to deploy.
Containers are used as only runtime environment, all the sourcecode lives on the host.

Containers are named after capistrano release directories, so for each release you will provided with a docker conatiner.

Example:

releases         |    | containers
-----------------|----|----------------------
20150509224056   | -> | my_app_20150509224056
20150509224500   | -> | my_ap_20150509224500

Contanier mount these directories from the host
* current release folder (eg: deploy/eleases/20150509224056)
* shared                 (eg: deploy/shared)
* gemset (optional)      (eg: /home/user/.rvm/gems/ruby-2.1.5@my_app)

The files entirely stored on the host.
Gems are also installed on host and gemset path is imported into container this way gems not duplicated among containers. The container sees the current_path, shared_path an if set the gemset path.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cap-docker'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cap-docker

### Capfile
require 'capistrano/docker'

## Flow

### Simple

With simple flow you specify a port on which your docker container listen and when the code deploy is done. There is
short blank period since the old container which listen on the exact same port must be stopped and a new one should start up.

Run ```cap docker:deploy``` which invoke the following steps:

```ruby
cap deploy                        # Run the regular deploy
cap docker:forward:stop_previous  # Stop previous instance
cap docker:run                    # Invoke docker run 
cap docker:ping                   # Wake application up
```

### With live preview (work in progress)

On new release the old conatiner by default will be switched off and new container with the new
current_path will serve requesets.

There are two main reason why live preview exists:
* zero downtime 
  The new container brought up in the background and when it it up and running ports swaped with previous version
  and the old version get suspended
* live preview
  Deploy to production see how it behave and if statisfied it only needs to change the listen ports.

However if you would like to have old and new to work simultaneously on differnt ports for exmple: live preview.
This will keep both running:

``` cap deploy:docker:preview ```

When you finished and decided to go live:

``` cap deploy:docker:golive ```

## Usage

### Commands

```ruby
cap docker:deploy                # Full deploy, stop previous container
cap docker:preview               # Prerelease, deploy a new version while the old one available for the public
cap docker:golive                # Replace old version with new one
cap docker:rollback              # If something goes wrong ;)
cap docker:cleanup               # Remove old containers
```

### Variables

```ruby
set :docker_use, true                              # set false if you don't want to use it on a host
set :docker_host, [:host]                          # On which roles should docker command exceuted
set :docker_current_path, current_path             # Within container app will mounted into this directory
set :docker_shared_path, shared_path               # Shared path within container
set :docker_gemset_path, "host_path:guest_path"    # gemset path, no default, if not set not in use
set :dcoker_baseimage, ""                          # Specify the baseimage will be use to generate container
set :docker_prefix, "myapp"                        # Dcoker container name: prefix + capistarno directory name, eg: myapp_20150509174653
set :docker_port, 3000                             # Dcoker container exposed port
set :docker_preview_port, 3001                     # Port on host to see how new release will looks like
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/cap-docker/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
