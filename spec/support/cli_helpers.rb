# frozen_string_literal: true

require "thor"
require "fileutils"
require "esse/cli"

module CliHelpers
  def self.included(base)
    base.before do
      allow(Esse.config).to receive(:cli_event_listeners?).and_return(false)
    end

    base.after do
      reset_config!
    end
  end

  def cli_exec(command)
    quietly { Esse::CLI.start(command) }
  end

  protected

  def silence_stream(stream)
    old_stream = stream.dup
    stream.reopen(IO::NULL)
    stream.sync = true
    yield
  ensure
    stream.reopen(old_stream)
    old_stream.close
  end

  def quietly
    silence_stream($stdout) do
      silence_stream($stderr) do
        yield
      end
    end
  end
end

RSpec.configure do |config|
  config.include CliHelpers, type: :cli
end
