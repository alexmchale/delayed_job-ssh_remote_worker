require 'delayed/ssh_remote_worker'
require 'rails'

module Delayed
  class SshRemoteWorker
    class Railtie < Rails::Railtie

      railtie_name :delayed_job_ssh_remote_worker

      rake_tasks do
        load "delayed/ssh_remote_worker/tasks.rb"
      end

    end
  end
end
