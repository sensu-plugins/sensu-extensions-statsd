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
            expect(output).to match(/foo\.statsd\.gauges\.tcp 1\.0/)
            expect(output).to match(/foo\.statsd\.gauges\.udp 2\.0/)
            expect(status).to eq(0)
            async_done
          end
        end
      end
    end
  end

  it "can support relative gauges" do
    async_wrapper do
      timer(1) do
        EM::connect("127.0.0.1", 8125, nil) do |socket|
          data = "tcp:+4|g"
          socket.send_data(data)
          socket.close_connection_after_writing
        end
        EM::open_datagram_socket("127.0.0.1", 0, nil) do |socket|
          data = "udp:-2|g"
          socket.send_datagram(data, "127.0.0.1", 8125)
          socket.close_connection_after_writing
        end
        EM::open_datagram_socket("127.0.0.1", 0, nil) do |socket|
          data = "udp:-2|g"
          socket.send_datagram(data, "127.0.0.1", 8125)
          socket.close_connection_after_writing
        end
        timer(3) do
          @extension.safe_run do |output, status|
            expect(output).to match(/foo\.statsd\.gauges\.tcp 4\.0/)
            expect(output).to match(/foo\.statsd\.gauges\.udp -4\.0/)
            expect(status).to eq(0)
            async_done
          end
        end
      end
    end
  end

  it "can support counters with sampling" do
    async_wrapper do
      timer(1) do
        EM::connect("127.0.0.1", 8125, nil) do |socket|
          data = "tcp:1|c|@0.1"
          socket.send_data(data)
          socket.close_connection_after_writing
        end
        EM::open_datagram_socket("127.0.0.1", 0, nil) do |socket|
          data = "udp:1|c"
          socket.send_datagram(data, "127.0.0.1", 8125)
          socket.close_connection_after_writing
        end
        EM::open_datagram_socket("127.0.0.1", 0, nil) do |socket|
          data = "udp:1|c"
          socket.send_datagram(data, "127.0.0.1", 8125)
          socket.close_connection_after_writing
        end
        timer(3) do
          @extension.safe_run do |output, status|
            expect(output).to match(/foo\.statsd\.counters\.tcp 10/)
            expect(output).to match(/foo\.statsd\.counters\.udp 2/)
            expect(status).to eq(0)
            async_done
          end
        end
      end
    end
  end

  it "can support timers with sampling" do
    async_wrapper do
      timer(1) do
        EM::connect("127.0.0.1", 8125, nil) do |socket|
          data = "tcp:320|ms|@0.1"
          socket.send_data(data)
          socket.close_connection_after_writing
        end
        EM::open_datagram_socket("127.0.0.1", 0, nil) do |socket|
          data = "udp:360|ms"
          socket.send_datagram(data, "127.0.0.1", 8125)
          socket.close_connection_after_writing
        end
        EM::open_datagram_socket("127.0.0.1", 0, nil) do |socket|
          data = "udp:385|ms"
          socket.send_datagram(data, "127.0.0.1", 8125)
          socket.close_connection_after_writing
        end
        timer(3) do
          @extension.safe_run do |output, status|
            expect(output).to match(/foo\.statsd\.timers\.tcp.lower 3200\.0/)
            expect(output).to match(/foo\.statsd\.timers\.tcp.upper 3200\.0/)
            expect(output).to match(/foo\.statsd\.timers\.tcp.upper_90 3200\.0/)
            expect(output).to match(/foo\.statsd\.timers\.tcp.mean 3200\.0/)
            expect(output).to match(/foo\.statsd\.timers\.udp.lower 360\.0/)
            expect(output).to match(/foo\.statsd\.timers\.udp.upper 385\.0/)
            expect(output).to match(/foo\.statsd\.timers\.udp.upper_90 385\.0/)
            expect(output).to match(/foo\.statsd\.timers\.udp.mean 372\.5/)
            expect(status).to eq(0)
            async_done
          end
        end
      end
    end
  end

  it "can behave like etsy's implementation (i.e resets) with defaults" do
    async_wrapper do
      timer(1) do
        EM::connect("127.0.0.1", 8125, nil) do |socket|
          data = "tcp:1|g"
          socket.send_data(data)
          socket.close_connection_after_writing
        end
        EM::connect("127.0.0.1", 8125, nil) do |socket|
          data = "tcp:1|c"
          socket.send_data(data)
          socket.close_connection_after_writing
        end
        EM::connect("127.0.0.1", 8125, nil) do |socket|
          data = "tcp:1|ms"
          socket.send_data(data)
          socket.close_connection_after_writing
        end
        timer(3) do
          @extension.safe_run do |output, status|
            expect(output.split("\n").size).to be > 7
            expect(status).to eq(0)
            async_done
          end
        end
      end
    end
  end

  it "can support deleting gauges, counters, and timers on flush" do
    @extension.settings = {
      :client => {
        :name => "foo"
      },
      :statsd => {
        :flush_interval => 1,
        :delete_gauges => true,
        :delete_counters => true,
        :delete_timers => true
      }
    }
    async_wrapper do
      timer(1) do
        EM::connect("127.0.0.1", 8125, nil) do |socket|
          data = "tcp:1|g"
          socket.send_data(data)
          socket.close_connection_after_writing
        end
        EM::connect("127.0.0.1", 8125, nil) do |socket|
          data = "tcp:1|c"
          socket.send_data(data)
          socket.close_connection_after_writing
        end
        EM::connect("127.0.0.1", 8125, nil) do |socket|
          data = "tcp:1|ms"
          socket.send_data(data)
          socket.close_connection_after_writing
        end
        timer(3) do
          @extension.safe_run do |output, status|
            expect(output.split("\n").size).to eq(7)
            expect(status).to eq(0)
            async_done
          end
        end
      end
    end
  end
end
