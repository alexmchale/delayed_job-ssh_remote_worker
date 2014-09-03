namespace :jobs do

  task :create_port_tunnel do
    load_yaml = -> filename {
      filename =
        if defined?(Rails)
          Rails.root.join("config", filename)
        else
          File.join("config", filename)
        end

      if File.file? filename
        YAML.load File.read filename
      end
    }

    get_hash = -> hash, key {
      hash2 = hash[key.to_s.strip]

      if hash2.kind_of? Hash
        hash2
      else
        hash
      end
    }

    config = load_yaml["remote_database.yml"] || load_yaml["database.yml"]
    config = get_hash[config, ENV["REMOTE_ENV"]]
    config = get_hash[config, Rails.env.to_s]

    $ssh_remote_worker = Delayed::SshRemoteWorker.new(config)
    $ssh_remote_worker and $ssh_remote_worker.create_port_tunnel
  end

  task :connect_to_tunneled_database do
    $ssh_remote_worker and $ssh_remote_worker.connect_to_tunneled_database
  end

  task :destroy_port_tunnel do
    $ssh_remote_worker and $ssh_remote_worker.destroy_port_tunnel
    $ssh_remote_worker = nil
  end

  desc "Start a remote delayed_job worker"
  task :remote_work => %w(
    jobs:create_port_tunnel
    jobs:connect_to_tunneled_database
    jobs:work
    jobs:destroy_port_tunnel
  )

  desc "Start a remote delayed_job worker and exit when all available jobs are complete"
  task :remote_workoff => %w(
    jobs:create_port_tunnel
    jobs:connect_to_tunneled_database
    jobs:workoff
    jobs:destroy_port_tunnel
  )

end
