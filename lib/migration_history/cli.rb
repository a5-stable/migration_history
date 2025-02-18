# frozen_string_literal: true

require "thor"
require "erb"
require "migration_history"
require "migration_history/formatter/base"
require "migration_history/formatter/html_formatter"

module MigrationHistory
  class CLI < Thor
    desc "filter", "フィルタリングしてマイグレーション履歴を取得"
    option :table, required: true, desc: "テーブル名"
    option :column, required: false, desc: "カラム名"
    option :action, required: false, desc: "アクション名"
    option :output, required: false, desc: "HTML出力ファイル名"
    def filter
      table_name = options[:table]
      column_name = options[:column]
      action_name = options[:action]

      result = MigrationHistory.filter(table_name, column_name, action_name)

      if options[:output]
        generate_html(result, options[:output])
      else
        result.original_result.each do |_, entry|
          puts "ClassName: #{entry[:class_name]}, Timestamp: #{entry[:timestamp]}"
        end
      end
    end

    desc "all", "全てのマイグレーション履歴を取得"
    option :output, required: false, desc: "HTML出力ファイル名"
    def all
      result = MigrationHistory.all

      if options[:output]
        generate_html(result, options[:output])
      else
        result.original_result.each do |_, entry|
          puts "ClassName: #{entry[:class_name]}, Timestamp: #{entry[:timestamp]}"
        end
      end
    end

    private
      def generate_html(result, output_file)
        Formatter::HTMLFormatter.new.format(result)
        puts "output to #{output_file}"
      end
  end
end
