require File.join(File.dirname(__FILE__), "helpers")
require "sensu/extensions/statsd"

describe "Sensu::Extension::StatsD" do
  include Helpers

  before do
    @extension = Sensu::Extension::StatsD.new
    @extension.settings = {
      :flush_interval => 1
    }
    @extension.logger = Sensu::Logger.get(:log_level => :fatal)
  end

  it "can run" do
    async_wrapper do
      @extension.safe_run(event_template) do |output, status|
        expect(output).to eq("")
        expect(status).to eq(0)
        async_done
      end
    end
  end
end
