# Cap::Docker

TODO: Write a gem description

The files entirely stored on the host.
Gems are also installed on host and gemset path is imported into container.
The container sees the current_path, shared_path an if set the gemset path.

On new release the old conatiner by default will be switched off and new container with the new
current_path will serve requesets.

There are two main reason why i developed this gem:
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


```ruby
set :docker_host, [:host]                          # On which roles should docker command exceuted
set :docker_current_path, fetch(:current_path)     # Within container app will mounted into this directory
set :docker_shared_path, fetch(:current_path)      # Shared path within container
set :docker_gemset_path, "host_path:guest_path"    # gemset path, no default, if not set not in use
set :dcoker_baseimage, ""                          # Specify the baseimage will be use to generate container
set :docker_prefix, "myapp"                        # Dcoker container name: prefix + capistarno directory name, eg: myapp_20150509174653
```


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cap-docker'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cap-docker

# Capfile
require 'capistrano/docker'

## Usage

cap deploy:docker
cap deploy:docker:run               # Prerelease, deploy a new version while the old one available for the public
cap deploy:docker:golive            # Replace old version with new one
cap deploy:docker:rollback          # If something goes wrong ;)
cap deploy:docker:cleanup           # Remove old containers

## Contributing

1. Fork it ( https://github.com/[my-github-username]/cap-docker/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
