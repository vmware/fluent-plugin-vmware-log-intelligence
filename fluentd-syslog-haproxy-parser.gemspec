
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name    = "fluentd-syslog-haproxy-parser"
  spec.version = "0.0.1"
  spec.authors = ["slk"]
  spec.email   = ["slk244@vmware.com"]

  spec.summary       = "An haproxy syslog parser"
  spec.description   = "An haproxy syslog log parser"
  spec.homepage      = "https://github.com/slk244/fluentd-syslog-haproxy-parser"
  spec.license       = "AGPL-3.0"

  spec.files         = ["./lib/fluent/plugin/parser_haproxy_syslog.rb"]
  spec.executables   = []
  spec.require_paths = ["lib"]
end
