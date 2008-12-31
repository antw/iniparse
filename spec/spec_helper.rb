$TESTING=true
$:.push File.join(File.dirname(__FILE__), '..', 'lib')
require 'iniparse'

# Taken from Merb Core's spec helper.
# Merb is licenced using the MIT License and is copyright Engine Yard Inc.

module IniParse
  module SpecHelpers
    class BeKindOf
      def initialize(expected) # + args
        @expected = expected
      end

      def matches?(target)
        @target = target
        @target.kind_of?(@expected)
      end

      def failure_message
        "expected #{@expected} but got #{@target.class}"
      end

      def negative_failure_message
        "expected #{@expected} to not be #{@target.class}"
      end

      def description
        "be_kind_of #{@target}"
      end
    end

    def be_kind_of(expected) # + args
      BeKindOf.new(expected)
    end
  end
end

Spec::Runner.configure do |config|
  config.include(IniParse::SpecHelpers)
end
