namespace :docker do
  desc 'Create new container'
  task :run do
    on roles(fetch(:docker_host, :all)) do
      cmd = ["docker run", switches, name, volumes, baseimage].join(' ')
      execute cmd
    end
  end
  after 'deploy:finished', 'docker:run'

  task :remove, [:release] do |t, args|
    args.with_defaults(release_path: "current")
    execute "dcoker rm #{name}"
  end

  desc 'Stop and remove container'
  task :stop_and_remove do
    #last_release = capture(:ls, '-xt', releases_path).split.first
    invoke :stop
    invoke :remove
  end
  before 'deploy:cleanup_rollback', 'docker:stop_and_remove'


  def switches
    "--detach --publish-all"
  end

  def name
    "--name #{container_name(release_path)}"
  end

  def container_name(path)
    "#{fetch(:docker_prefix)}_#{path_basename(path)}"
  end

  def volumes
    ["-v #{release_path}:#{current_path}",
     "-v #{shared_path}:#{shared_path}",
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

  namespace :deploy do

    # After new release go live stop previous container
    task :stop_previous do
      on roles(fetch(:docker_host, :all)) do
        prev_release_path = capture(:ls, '-xt', releases_path).split[1]
        execute "docker kill #{container_name(prev_release_path)}"
      end
    end
    after 'deploy:finished', "docker:deploy:stop_previous"
  end # namespace :stop

end

namespace :load do
  task :defaults do
  end
end
