# Sensu StatsD Extension

A StatsD implementation for the Sensu client. This check extension
creates a StatsD TCP & UDP listener, receives StatsD metrics, parses
them, and flushes them to the Graphite plaintext format for Sensu to
send to Graphite or another TSDB.

This StatsD implementation attempts to adhere to [Etsy's metric type
specifications](https://github.com/etsy/statsd/blob/master/docs/metric_types.md).

[![Build Status](https://travis-ci.org/sensu-extensions/sensu-extensions-statsd.svg?branch=master)](https://travis-ci.org/sensu/sensu-extensions-statsd)

## Installation

This extension requires Sensu version >= 0.26.

On a Sensu client machine.

```
sensu-install -e statsd:1.0.0
```

Edit `/etc/sensu/conf.d/extensions.json` to load it.

``` json
{
  "extensions": {
    "statsd": {
      "version": "1.0.0"
    }
  }
}
```

Restart the Sensu client.

``` shell
sudo service sensu-client restart
```

## Configuration

Edit `/etc/sensu/conf.d/statsd.json` to change its configuration.

``` json
{
  "statsd": {
    "bind": "0.0.0.0"
  }
}
```

The following defaults make the integration behave like Etsy's StatsD
implementation.

|attribute|type|default|description|
|----|----|----|---|
|bind|string|"127.0.0.1"|IP to bind the StatsD sockets to|
|port|integer|8125|Port to bind the StatsD sockets to|
|flush_interval|integer|10|The StatsD flush interval|
|send_interval|integer|30|How often Graphite metrics are sent to Sensu|
|percentile|integer|90|The percentile to calculate for StatsD metrics|
|add_client_prefix|boolean|true|If the Sensu client name should prefix the Graphite metric path|
|path_prefix|string|"statsd"|The optional Graphite metric path prefix (after client name)|
|add_path_prefix|boolean|true|If the path_prefix should be used|
|delete_gauges|boolean|false|If gauges that have not been updated should be deleted instead of flushed|
|delete_counters|boolean|false|If counters with a value of 0 should be deleted instead of flushed|
|delete_timers|boolean|false|If timers with a count of 0 should be deleted instead of flushed|
|reset_gauges|boolean|false|If gauges should be reset to 0 after flushing|
|reset_counters|boolean|true|If counters should be reset to 0 after flushing|
|reset_timers|boolean|true|If timers should be reset/cleared after flushing|
|handler|string|"graphite"|Handler to use for the Graphite metrics|

## Example

Test the StatsD TCP socket:

``` shell
echo "orders:1|c" | nc 127.0.0.1 8125
```
