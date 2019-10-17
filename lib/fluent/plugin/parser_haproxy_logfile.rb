require "fluent/plugin/parser"
require "base64"

module Fluent
  module Plugin
    class HaproxyParser < Parser
      Plugin.register_parser("haproxy_logfile", self)

      REGEXP = /^(?<ps>\w+)\[(?<pid>\d+)\]: (?<c_ip>[\w\.]+):(?<c_port>\d+) \[(?<hatime>.+)\] (?<f_end>.+) (?<b_end>.+)\/(?<b_server>.+) (?<tq>[+-]\d+|\d+)\/(?<tw>[+-]\d+|\d+)\/(?<tc>[+-]\d+|\d+)\/(?<tr>[+-]\d+|\d+)\/(?<tt>[+-]\d+|\d+) (?<status_code>\d+) (?<size>[+-]\d+|\d+) (?<req_cookie>\S+) (?<res_cookie>\S+) (?<t_state>[\w-]+) (?<actconn>[+-]\d+|\d+)\/(?<feconn>[+-]\d+|\d+)\/(?<beconn>[+-]\d+|\d+)\/(?<srv_conn>[+-]\d+|\d+)\/(?<retries>[+-]\d+|\d+) (?<srv_queue>[+-]\d+|\d+)\/(?<backend_queue>[+-]\d+|\d+) \{?(?<req_headers>[^}]*)\}? ?\{?(?<res_headers>[^}]*)\}? ?"(?<method>\w+) (?<path>.+) /

      config_param :headers, :array, default: []
      def configure(conf)
        super
      end

      def parse(text)
        m = REGEXP.match(text)
        unless m
          yield nil, nil
          return
        end

        r = {}
        m.names.each do |name|
          if value = m[name]
            r[name] = value
          end
        end

        #Preserve the actual complete log
        r["message"] = text

        time, record = convert_values(parse_time(r), r)

        record["tq"] = Integer(record["tq"])
        record["tw"] = Integer(record["tw"])
        record["tc"] = Integer(record["tc"])
        record["tr"] = Integer(record["tr"])
        record["tt"] = Integer(record["tt"])
        record["retries"] = Integer(record["retries"])
        record["size"] = Integer(record["size"])
        record["actconn"] = Integer(record["actconn"])
        record["feconn"] = Integer(record["feconn"])
        record["beconn"] = Integer(record["beconn"])
        record["srv_conn"] = Integer(record["srv_conn"])
        record["srv_queue"] = Integer(record["srv_queue"])
        record["backend_queue"] = Integer(record["backend_queue"])

        yield time, record
      end
    end
  end
end
