require "migration_history/formatter/base"
require "migration_history/formatter/html_formatter"

module MigrationHistory
  class ResultSet
    attr_accessor :original_result

    def initialize(original_result)
      @original_result = original_result
    end

    def format!
      formatter = HTMLFormatter.new
      formatter.format(self)
    end
  end
end
