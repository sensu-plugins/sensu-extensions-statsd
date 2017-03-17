require File.join(File.dirname(__FILE__), "helpers")
require "sensu/extensions/statsd"

describe "Sensu::Extension::StatsD" do
  include Helpers

  before do
    @extension = Sensu::Extension::StatsD.new
    @extension.settings = {
      :client => {
        :name => "foo"
      },
      :statsd => {
        :flush_interval => 1
      }
    }
    @extension.logger = Sensu::Logger.get(:log_level => :fatal)
  end

  it "can run" do
    async_wrapper do
      @extension.safe_run do |output, status|
        expect(output).to eq("")
        expect(status).to eq(0)
        async_done
      end
    end
  end

  it "can create graphite plaintext metrics" do
    async_wrapper do
      timer(1) do
        EM::connect("127.0.0.1", 8125, nil) do |socket|
          data = "tcp:1|g"
          socket.send_data(data)
          socket.close_connection_after_writing
        end
        EM::open_datagram_socket("127.0.0.1", 0, nil) do |socket|
          data = "udp:2|g"
          socket.send_datagram(data, "127.0.0.1", 8125)
          socket.close_connection_after_writing
        end
        timer(3) do
          @extension.safe_run do |output, status|
            expect(output).to match(/statsd\.gauges\.tcp 1\.0/)
            expect(output).to match(/statsd\.gauges\.udp 2\.0/)
            expect(status).to eq(0)
            async_done
          end
        end
      end
    end
  end
end
