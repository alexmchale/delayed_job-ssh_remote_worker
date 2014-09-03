require "delayed/ssh_remote_worker/version"
require "net/ssh/gateway"

module Delayed
  class SshRemoteWorker

    attr_reader :remote_ssh_username, :remote_ssh_hostname, :remote_ssh_port
    attr_reader :remote_db_hostname, :remote_db_port
    attr_reader :local_db_hostname, :local_db_port
    attr_reader :gateway_ssh, :gateway_port
    attr_reader :gateway_in_rd, :gateway_in_wr
    attr_reader :gateway_out_rd, :gateway_out_wr
    attr_reader :child
    attr_reader :config

    def initialize(config)
      @config              = Hash[config.map { |k, v| [ k.to_sym, v ] }]
      @debug               = !!@config[:ssh_debug]

      @remote_ssh_username = @config[:ssh_username]
      @remote_ssh_hostname = @config[:ssh_hostname]
      @remote_ssh_port     = @config[:ssh_port].to_i
      @remote_ssh_port     = 22 if remote_ssh_port <= 0

      @remote_db_hostname  = @config[:host].to_s.strip
      @remote_db_hostname  = "localhost" if remote_db_hostname == ""
      @remote_db_port      = @config[:port].to_i
      @remote_db_port      = default_port_number(@config[:adapter]) if remote_db_port <= 0

      @local_db_hostname = "127.0.0.1"
      @local_db_port     = nil
    end

    def create_port_tunnel
      # Create two pipes - one will be used to get the port number from the child
      # process, the other will be used to tell the child process when it's time
      # to exit.
      ( @gateway_in_rd  , @gateway_in_wr  ) = IO.pipe
      ( @gateway_out_rd , @gateway_out_wr ) = IO.pipe

      # The child process will establish the SSH connection to the database server.
      @child = fork {
        debug "CHILD: Tunneling to #{ remote_db_hostname }:#{ remote_db_port } on #{ remote_ssh_username }@#{ remote_ssh_hostname }:#{ remote_ssh_port }."

        @gateway_ssh  = Net::SSH::Gateway.new(remote_ssh_hostname, remote_ssh_username, port: remote_ssh_port)
        @gateway_port = gateway_ssh.open(remote_db_hostname, remote_db_port)

        debug "CHILD: Notifying parent process of gateway port number #{ gateway_port }."

        gateway_out_rd.close
        gateway_out_wr.write(gateway_port.to_s)
        gateway_out_wr.close

        debug "CHILD: Waiting for parent to close pipe."

        gateway_in_wr.close
        gateway_in_rd.read
        gateway_in_rd.close

        debug "CHILD: Parent closed pipe. Exiting."

        gateway_ssh.shutdown!
      }

      # Get the port number back from the child process once the SSH connection is established.
      debug "PARENT: Reading port number from child."
      gateway_out_wr.close
      @local_db_port = Integer(gateway_out_rd.read)
      gateway_out_rd.close

      # Log and proceed with the next task.
      debug "PARENT: Received port number #{ gateway_port } from child. Proceeding with execution."
    end

    def connect_to_tunneled_database
      # Load just ActiveRecord. Do this before any part of the native Rails project is loaded.
      require "active_record"

      # Connect to the remote Postgres database.
      ActiveRecord::Base.establish_connection(activerecord_config)

      # Log a simple query just to verify that we actually have a connection.
      debug "Connected to remote Postgres. Found #{ User.count } users in the remote database."
    end

    def destroy_port_tunnel
      # Close the pipe with the gateway, indicating that it should close.
      debug "PARENT: Closing pipe with child to terminate gateway."
      gateway_in_wr.close
      gateway_in_rd.close
      Process.wait(child)
    end

    private

    def default_port_number(adapter)
      case adapter.to_s.strip
      when /mysql/i    then 3306
      when /postgres/i then 5432
      else raise "no known default port number for adapter #{ adapter.inspect }"
      end
    end

    def activerecord_config
      config.merge({
        :host => local_db_hostname ,
        :port => local_db_port     ,
      })
    end

    def debug(message)
      @debug and puts(message)
    end

  end
end
