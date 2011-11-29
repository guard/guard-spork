module Guard
  class Spork
    class SporkInstance
      attr_reader :port

      def initialize(type, port, env, options)
        @type = type
        @port = port
        @env = env
        @options = options
      end

      def command
        parts = []
        parts << "bundle exec" if use_bundler?
        parts << "spork"

        if type == :test_unit
          parts << "testunit"
        elsif type == :cucumber
          parts << "cu"
        end

        parts << "-p #{port}"
        parts.join(" ")
      end

      private
        attr_reader :options, :type

        def use_bundler?
          options[:bundler]
        end
    end
  end
end
