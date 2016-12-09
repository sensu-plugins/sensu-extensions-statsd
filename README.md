# Sensu StatsD Extension

A StatsD implementation for the Sensu client. This check extension
creates a StatsD TCP & UDP listener, receives StatsD metrics, parses
them, and flushes them to the Graphite plaintext format for Sensu to
send to Graphite or another TSDB.

## Installation

On a Sensu client machine.

```
sensu-install -e statsd
```

Edit `/etc/sensu/conf.d/extensions.json` to load it.

``` json
{
  "extensions": {
    "statsd": {
      "version": "0.0.1"
    }
  }
}
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

|param|type|default|description|
|----|----|----|---|
|bind|string|"127.0.0.1"|IP to bind the StatsD sockets to|
|port|integer|8125|Port to bind the StatsD sockets to|
|flush_interval|integer|10|The StatsD flush interval|
|send_interval|integer|30|How often Graphite metrics are sent to Sensu|
|percentile|integer|90|The percentile to calculate for StatsD metrics|
|add_client_prefix|boolean|true|If the Sensu client name should prefix the Graphite metric path|
|path_prefix|string|"statsd"|The optional Graphite metric path prefix (after client name)|
|add_path_prefix|boolean|true|If the path_prefix should be used|
|handler|string|"graphite"|Handler to use for the Graphite metrics|
