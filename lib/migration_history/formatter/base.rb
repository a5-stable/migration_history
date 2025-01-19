# frozen_string_literal: true

module MigrationHistory
  module Formatter
    class Base
      def initialize
        @migration_actions = []
      end

      def format(result_set)
        raise NotImplementedError
      end
    end
  end
end
