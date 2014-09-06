# DelayedJob::SshRemoteWorker

This gem provides a rake task for executing DelayedJob backed by ActiveRecord
remotely over an SSH connection.

## Installation

Add this line to your application's Gemfile:

    gem 'delayed_job-ssh_remote_worker'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install delayed_job-ssh_remote_worker

## Usage

This gem provides two Rake tasks - `jobs:remote_work` and `jobs:remote_workoff`.

### Run all jobs continuously

    rake jobs:remote_work

This rake task will run an infinite loop, polling the remote server for new
delayed jobs to run.

### Run jobs that are currently in the queue

    rake jobs:remote_workoff

This rake task runs the jobs that are currently in the queue, then exits.

## Configuration

Require the gem and either create a `config/remote_database.yml` file that
contains a record such as below:

```yaml
production:
  ssh_hostname: "example.com"
  ssh_username: "app"
  adapter:      "postgresql"
  encoding:     "unicode"
  database:     "dbname"
  username:     "dbuser"
  password:     "pa$$word"
```

Alternatively, the `ssh_hostname` and `ssh_username` can be simply added to an
entry in `config/database.yml`. You may specify the SSH port number as `ssh_port`.

The `config/remote_database.yml` top level keys can have names other than your
`Rails.env`. For example:

```yaml
fast_server:
  ssh_hostname: "example.com"
  ssh_username: "app"
  ssh_port:     20022
  adapter:      "postgresql"
  encoding:     "unicode"
  database:     "dbname"
  username:     "dbuser"
  password:     "pa$$word"

slow_server:
  ssh_hostname: "example2.com"
  ssh_username: "app"
  adapter:      "mysql"
  encoding:     "unicode"
  database:     "dbname"
  username:     "dbuser"
  password:     "pa$$word"
```

The key can then be specified in `ENV['REMOTE_ENV']` thusly:

```bash
RAILS_ENV=production REMOTE_ENV=fast_server bundle exec rake jobs:remote_workoff
```

If `ENV['REMOTE_ENV']` is not set, `delayed_job-ssh_remote_worker` will default to `Rails.env`.

## Contributing

1. Fork it ( https://github.com/alexmchale/delayed_job-ssh_remote_worker/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
