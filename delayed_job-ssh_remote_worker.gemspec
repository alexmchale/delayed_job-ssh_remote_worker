# encoding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'delayed/ssh_remote_worker/version'

Gem::Specification.new do |spec|

  spec.name          = "delayed_job-ssh_remote_worker"
  spec.version       = DelayedJob::SshRemoteWorker::VERSION
  spec.authors       = ["Alex McHale"]
  spec.email         = ["alex@anticlever.com"]
  spec.summary       = %q{Run DelayedJob queues over SSH in a remote database}
  spec.description   = %q{Provides a few rake tasks to run DelayedJob jobs on a remote server over SSH}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "delayed_job_active_record"
  spec.add_dependency "net-ssh-gateway"

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"

end
