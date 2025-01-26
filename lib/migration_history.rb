# frozen_string_literal: true

require "migration_history/cli"
require "migration_history/query"
require "active_record"
require "rails"

module MigrationHistory
  include QueryMethods
  class InvalidError
    def initialize(message)
      @message = message
    end
  end
end
