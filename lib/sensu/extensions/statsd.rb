require "sensu/extension"

module Sensu
  module Extension
    class StatsDSimpleSocket < EM::Connection
      attr_accessor :data

      def receive_data(data)
        @data << data
      end
    end

    class StatsD < Check
      def name
        "statsd"
      end

      def description
        "a statsd implementation"
      end

      def options
        return @options if @options
        @options = {
          :bind => "127.0.0.1",
          :port => 8125,
          :flush_interval => 10,
          :send_interval => 30,
          :percentile => 90,
          :delete_gauges => false,
          :delete_counters => false,
          :delete_timers => false,
          :reset_gauges => false,
          :reset_counters => true,
          :reset_timers => true,
          :add_client_prefix => true,
          :path_prefix => "statsd",
          :add_path_prefix => true,
          :handler => "graphite"
        }
        @options.merge!(@settings[:statsd]) if @settings[:statsd].is_a?(Hash)
        @options
      end

      def definition
        {
          :type => "metric",
          :name => name,
          :interval => options[:send_interval],
          :standalone => true,
          :output_format => "graphite_plaintext",
          :handler => options[:handler]
        }
      end

      def post_init
        @flush_timers = []
        @data = EM::Queue.new
        @gauges = Hash.new { |h, k| h[k] = 0 }
        @counters = Hash.new { |h, k| h[k] = 0 }
        @timers = Hash.new { |h, k| h[k] = [] }
        @metrics = []
        setup_flush_timers
        setup_parser
        setup_statsd_socket
      end

      def run
        output = ""
        if @metrics
          output << @metrics.join("\n") + "\n" unless @metrics.empty?
          @logger.info("statsd collected metrics", :count => @metrics.count)
          @metrics = []
        end
        yield output, 0
      end

      private

      def clean(hash, delete=false, reset=false)
        if delete
          hash.delete_if do |key, value|
            value == 0 || value == []
          end
        end
        if reset
          hash.each do |key, value|
            hash[key] = (value.is_a?(Array) ? [] : 0)
          end
        end
      end

      def add_metric(*args)
        value = args.pop
        path = []
        path << @settings[:client][:name] if options[:add_client_prefix]
        path << options[:path_prefix] if options[:add_path_prefix]
        path = (path + args).join(".")
        if path !~ /^[A-Za-z0-9\._-]*$/
          @logger.info("invalid statsd metric", {
            :reason => "metric path must only consist of alpha-numeric characters, periods, underscores, and dashes",
            :path => path,
            :value => value
          })
        else
          @logger.debug("adding statsd metric", {
            :path => path,
            :value => value
          })
          @metrics << [path, value, Time.now.to_i].join(" ")
        end
      end

      def flush!
        @gauges.each do |name, value|
          unless value == 0 && options[:delete_gauges]
            add_metric("gauges", name, value)
          end
        end
        clean(@gauges, options[:delete_gauges], options[:reset_gauges])
        @counters.each do |name, value|
          unless value == 0 && options[:delete_counters]
            add_metric("counters", name, value.to_i)
          end
        end
        clean(@counters, options[:delete_counters], options[:reset_counters])
        @timers.each do |name, values|
          unless values.empty? && options[:delete_timers]
            values.sort!
            length = values.length
            min = values.first || 0
            max = values.last || 0
            mean = min
            max_at_threshold = min
            percentile = options[:percentile]
            if length > 1
              threshold_index = ((100 - percentile) / 100.0) * length
              threshold_count = length - threshold_index.round
              valid_values = values.slice(0, threshold_count)
              max_at_threshold = valid_values[-1]
              sum = 0
              valid_values.each { |v| sum += v }
              mean = sum / valid_values.length
            end
            add_metric("timers", name, "lower", min)
            add_metric("timers", name, "mean", mean)
            add_metric("timers", name, "upper", max)
            add_metric("timers", name, "upper_#{percentile}", max_at_threshold)
          end
        end
        clean(@timers, options[:delete_timers], options[:reset_timers])
        @logger.debug("flushed statsd metrics")
      end

      def setup_flush_timers
        @flush_timers << EM::PeriodicTimer.new(options[:flush_interval]) do
          flush!
        end
      end

      def setup_parser
        parser = proc do |data|
          begin
            nv, type, raw_sample = data.strip.split("|")
            name, raw_value = nv.split(":")
            value = Float(raw_value)
            sample = Float(raw_sample ? raw_sample.split("@").last : 1)
            case type
            when "g"
              if raw_value.start_with?("+")
                @gauges[name] += value
              elsif raw_value.start_with?("-")
                @gauges[name] -= value.abs
              else
                @gauges[name] = value
              end
            when /^c/, "m"
              @counters[name] += value * (1 / sample)
            when "ms", "h", "t"
              @timers[name] << value * (1 / sample)
            end
          rescue => error
            @logger.error("statsd parser error", :error => error.to_s)
          end
          EM.next_tick do
            @data.pop(&parser)
          end
        end
        @data.pop(&parser)
      end

      def setup_statsd_socket
        @logger.debug("binding statsd tcp and udp sockets", :options => options)
        bind = options[:bind]
        port = options[:port]
        EM.start_server(bind, port, StatsDSimpleSocket) do |socket|
          socket.data = @data
        end
        EM.open_datagram_socket(bind, port, StatsDSimpleSocket) do |socket|
          socket.data = @data
        end
      end
    end
  end
end
