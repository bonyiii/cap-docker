# Cap::Docker

This project aims to make it simple to deploy an app inside Docker containers.

## Concept

You have a host and you set up a docker baseimage like this one. Once you have docker and  the basimage on your host you are ready to deploy.
Containers are used only as runtime environment, all the sourcecode lives on the hosti, installed by capistrano.
Gems are also installed on host and gemset path is imported into container this way gems not duplicated among containers.

Containers are named after capistrano release directories, so for each release you will provided with a docker conatiner.

Example:

releases         |    | containers
-----------------|----|----------------------
20150509224056   | -> | myapp_20150509224056
20150509224500   | -> | myap_20150509224500

Contanier mount these directories from the host
* current release folder (eg: deploy/eleases/20150509224056)
* shared                 (eg: deploy/shared)
* gemset (optional)      (eg: /home/user/.rvm/gems/ruby-2.1.5@myapp)

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
This is the default flow. It can be changed by setting ```docker_flow``` to something else.

With simple flow you specify a port on which your docker container listen (eg: docker run -p 3000:3000) and
when the code deploy is done the old container stopped and a new one will be go up. It means there is short
outage in the service while the one container stops and the other go live.

Run ```cap docker:deploy``` which invoke the following steps:

```ruby
cap deploy                        # Run the regular deploy
cap docker:forward:stop_previous  # Stop previous instance
cap docker:run                    # Invoke docker run
cap docker:ping                   # Wake application up
```

### With live preview (work in progress)
It can be enabled - even per host - this way: ```set :docker_flow, "preview"``` 

On new release the old conatiner by default will be switched off and new container with the new
current_path will serve requesets.

There are two main reason why live preview exists:
* zero downtime
  The new container brought up in the background and when it it up and running ports swaped with previous version
  and the old version get suspended
* live preview
  Deploy to production see how it behave and if statisfied it only needs to change the listen ports.

However if you would like to have old and new to run simultaneously on differnt ports for exmple: live preview.

This will keep both running:

``` cap deploy:docker:preview ```

When you ready to go live:

``` cap deploy:docker:golive ```

## Usage

### Commands

```ruby
cap docker:deploy      # Full deploy, stop previous container
cap docker:rollback    # If something goes wrong ;)
cap docker:start       # Start the current release container
cap docker:stop        # Stop the current release container

# Work in progress (preview flow)
cap docker:preview     # Prerelease, deploy a new version while the old one available for the public
cap docker:golive      # Replace old version with new one
```

### Variables

```ruby
# set false if you don't want to use it on a host
set :docker_use, true

# On which roles should docker command exceuted
set :docker_host, [:all]

# Within container app will mounted into this directory
set :docker_current_path, current_path

# Shared path within container
set :docker_shared_path, shared_path

# gemset path, no default, if not set not in use
set :docker_gemset_path, "host_path:guest_path"

# Specify the baseimage will be use to generate container
set :dcoker_baseimage, ""

# Dcoker container name: prefix + capistarno directory name,
# eg: myapp_20150509174653
set :docker_prefix, "myapp"

# Dcoker container exposed port
set :docker_port, 3000

# Simple or Preview
set :docker_flow, "simple"

# Port on host to see how new release will looks like
set :docker_preview_port, 3001
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/cap-docker/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
