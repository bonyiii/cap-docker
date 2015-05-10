namespace :docker do
  desc 'Create new container'
  task :deploy do
    next unless fetch(:docker_use)

    on roles(fetch(:docker_host, :all)) do
      invoke "deploy"
      invoke "docker:run"
      invoke "docker:ping"
      invoke "docker:forward:stop_previous"
    end
  end

  desc 'Deploy to new container while keep old one intact'
  task :preview do
    on roles(fetch(:docker_host, :all)) do
      next unless fetch(:docker_use)
      invoke "deploy"
      invoke "docker:run"
      invoke "docker:ping"
    end
  end

  task :run do
    next unless fetch(:docker_use)

    on roles(fetch(:docker_host, :all)) do
      cmd = ["docker run", options, name, volumes, baseimage].join(' ')
      execute cmd
    end

  end

  desc 'Warm up container with a request'
  task :ping do
    next unless fetch(:docker_use)

    on roles(fetch(:docker_host, :all), wait: 10) do
      execute :curl, '--silent', "localhost:#{current_port}"
    end
  end

  desc 'Stop current version container'
  task :stop do
    on roles(fetch(:docker_host, :all)) do
      next unless fetch(:docker_use)

      execute "docker stop #{container_name}"
    end
  end

  desc 'Start current version container'
  task :start do
    on roles(fetch(:docker_host, :all)) do
      next unless fetch(:docker_use)

      execute "docker start #{container_name}"
    end
  end

  desc 'Current release good to go live'
  task :golive do
    on roles(fetch(:docker_host, :all)) do
      next unless fetch(:docker_use)

      invoke 'docker:forward:stop_previous'
      # sudo maybe?
      #execute(:iptables, "-I DOCKER 1 -t nat -p tcp --dport #{fetch(:docker_preview_port)} -j REDIRECT --to-port #{current_port}")
    end
  end

  def options
    "--detach --publish-all"
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

  # Auxiliary task when go forward
  namespace :forward do
    # After new release go live stop previous container
    task :stop_previous do
      next unless fetch(:docker_use)

      on roles(fetch(:docker_host, :all)) do
        path = capture(:ls, '-xt', releases_path).split[1]
        stop(path)
      end
    end
    #after 'docker:deploy', "docker:forward:stop_previous"

    desc 'Stop all previous containers'
    task :stop_all_previous do
      next unless fetch(:docker_use)

      on roles(fetch(:docker_host, :all)) do
        paths = capture(:ls, '-xt', releases_path).split

        paths.drop(1).each do |path|
          stop(path)
        end
      end
    end

    desc 'Remove all previous containers'
    task :remove_all_previous do
      next unless fetch(:docker_use)

      on roles(fetch(:docker_host, :all)) do
        paths = capture(:ls, '-xt', releases_path).split

        paths.drop(1).each do |path|
          rm(path)
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
        #execute "docker kill #{container_name(prev_release_path)}"
        execute "docker stop #{container_name(path)}"
      else
        info "Container #{container_name(path)} was not running"
      end
    end
  end # namespace :stop

  # Auxiliary task when go backward
  namespace :rollback do
  end
end

namespace :load do
  task :defaults do
    set :docker_use, true
    set :docker_port, 3000
    set :docker_preview_port, 3001
  end
end
