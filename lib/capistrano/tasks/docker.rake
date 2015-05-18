namespace :docker do
  desc 'Deploy code and start a new container'
  task :deploy do
    on roles(fetch(:docker_host, :all)) do
      if fetch(:docker_flow) == "preview"
        invoke "docker:run"
        invoke "docker:forward:stop_previous"
      else
        invoke "docker:forward:stop_previous"
        if container_exists?(container_name)
          invoke "docker:start"
        else
          invoke "docker:run"
        end
      end
      invoke "docker:ping"
    end
  end

  desc 'Rollback code and start a new container'
  task :rollback do
    on roles(fetch(:docker_host, :all)) do
      invoke "docker:stop"
      invoke "deploy:rollback"
      if fetch(:docker_flow) == "preview"
        #invoke "docker:start"
        #invoke "docker:forward:stop_previous"
      else
        invoke "docker:start"
      end
      invoke "docker:ping"
    end
  end

  task :run do
    on roles(fetch(:docker_host, :all)) do
      cmd = ["docker run", options, name, volumes, baseimage].join(' ')
      execute cmd
    end
  end

  desc 'Warm up container with a request'
  task :ping do
    on roles(fetch(:docker_host, :all), wait: 10) do
      execute :curl, '--silent', "localhost:#{current_port}"
    end
  end

  desc 'Stop current version container'
  task :stop do
    on roles(fetch(:docker_host, :all)) do
      execute "docker stop #{container_name}"
    end
  end

  desc 'Start current version container'
  task :start do
    on roles(fetch(:docker_host, :all)) do
      execute "docker start #{container_name}"
    end
  end

  desc 'Deploy to new container while keep old one intact'
  task :preview do
    on roles(fetch(:docker_host, :all)) do
      invoke "deploy"
      invoke "docker:run"
      invoke "docker:ping"
    end
  end

  desc 'Current release good to go live'
  task :golive do
    on roles(fetch(:docker_host, :all)) do
      invoke 'docker:forward:stop_previous'
      # sudo maybe?
      #execute(:iptables, "-I DOCKER 1 -t nat -p tcp --dport #{fetch(:docker_preview_port)} -j REDIRECT --to-port #{current_port}")
    end
  end

  def options
    "--detach #{port_binding}"
  end

  def name
    "--name #{container_name(release_path)}"
  end

  def container_name(path = release_path)
    "#{fetch(:docker_prefix)}_#{path_basename(path)}"
  end

  def volumes
    ["-v #{release_path}:#{fetch(:docker_current_path, current_path)}",
     "-v #{shared_path}:#{fetch(:docker_shared_path, shared_path)}",
     gemset_volume
    ].join(' ')
  end

  def port_binding
    if fetch(:docker_flow) == "preview"
      "--publish-all"
    else
      "-p #{fetch(:docker_port)}:#{fetch(:docker_port)}"
    end
  end

  def baseimage
    fetch(:docker_baseimage)
  end

  def path_basename(path)
    Pathname.new(capture("readlink -f #{path}")).basename
  end

  def gemset_volume
    return unless fetch(:docker_gemset_path)
    "-v #{fetch(:docker_gemset_path)}"
  end

  def current_port
    capture(:docker, 'port', container_name, fetch(:docker_port)).split(':').last
  end

  def container_exists?(path)
    warn "container_exists?(#{path})"

    capture(:docker, "ps -a  | grep #{path} | wc -l").to_i > 0
  end

  # Auxiliary task when go forward (eg: deploy)
  namespace :forward do
    # After new release go live stop previous container
    task :stop_previous do
      on roles(fetch(:docker_host, :all)) do
        path = capture(:ls, '-xt', releases_path).split[1]
        stop(path) if container_exists?(path)
      end
    end
    #after 'docker:deploy', "docker:forward:stop_previous"

    desc 'Stop all previous containers'
    task :stop_all_previous do
      on roles(fetch(:docker_host, :all)) do
        paths = capture(:ls, '-xt', releases_path).split

        paths.drop(1).each do |path|
          stop(path) if container_exists?(path)
        end
      end
    end

    desc 'Remove all previous containers'
    task :remove_all_previous do
      on roles(fetch(:docker_host, :all)) do
        paths = capture(:ls, '-xt', releases_path).split

        paths.drop(1).each do |path|
          rm(path) if container_exists?(path)
        end
      end
    end

    def rm(path)
      execute "docker rm #{container_name(path)}"
    rescue
      warn "docker rm #{container_name(path)} failed"
    end

    def stop(path)
      running = capture(:docker, :inspect, "--format='{{ .State.Running }}'", container_name(path))
      if running == "true"
        # http://superuser.com/questions/756999/whats-the-difference-between-docker-stop-and-docker-kill
        execute "docker stop #{container_name(path)}"
      else
        info "Container #{container_name(path)} was not running"
      end
    end
  end # namespace :stop

  # Auxiliary task when go backward (eg: rollback)
  namespace :backward do
  end

end

namespace :load do
  task :defaults do
    set :docker_use, true
    set :docker_port, 3000
    set :docker_preview_port, 3001
    set :docker_flow, "simple"
  end
end

### HOOKS ###

# Hook for deploy process
# to override default task eg: deploy: :default
# it must be in the toplevel namespace
Rake::Task['deploy'].enhance do
  Rake::Task['docker:deploy'].invoke
end
#after 'deploy', 'docker:deploy'

# Hooks for rollback process
before 'deploy:rollback', 'docker:stop'
after 'deploy:rollback', 'docker:start'
