require "sensu/extension"

module Sensu
  module Extension
    class Template < Handler
      def name
        "template"
      end

      def description
        "extension template"
      end

      def run(event)
        yield "template", 0
      end
    end
  end
end
