namespace :docker do
  desc 'Create new container'
  task :run do
    next unless fetch(:docker_use)

    on roles(fetch(:docker_host, :all)) do
      cmd = ["docker run", options, name, volumes, baseimage].join(' ')
      execute cmd
    end
  end
  after 'deploy:finished', 'docker:run'

  desc 'Warm up container with a request'
  task :ping do
    next unless fetch(:docker_use)

    on roles(fetch(:docker_host, :all), wait: 10) do
      port = capture(:docker, 'port', container_name, fetch(:docker_port)).split(':').last
      execute :curl, '--silent', "localhost:#{port}"
    end
  end
  after 'docker:run', 'docker:ping'


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

  # Auxiliary task when go forward
  namespace :deploy do
    # After new release go live stop previous container
    task :stop_previous do
      next unless fetch(:docker_use)

      on roles(fetch(:docker_host, :all)) do
        prev_release_path = capture(:ls, '-xt', releases_path).split[1]
        running = capture(:docker, :inspect, "--format='{{ .State.Running }}'", container_name(prev_release_path))
        if running == "true"
          # http://superuser.com/questions/756999/whats-the-difference-between-docker-stop-and-docker-kill
          #execute "docker kill #{container_name(prev_release_path)}"
          execute "docker stop #{container_name(prev_release_path)}"
        end
      end
    end
    after 'deploy:finished', "docker:deploy:stop_previous"
  end # namespace :stop

  # Auxiliary task when go backward
  namespace :rollback do
  end
end

namespace :load do
  task :defaults do
    set :docker_use, true
    set :docker_port, 3000
  end
end
