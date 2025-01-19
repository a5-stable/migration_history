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
        result.each do |entry|
          puts "Timestamp: #{entry.timestamp}, Git Branch: #{entry.git_branch}, Git Commit: #{entry.git_commit}"
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
        result.each do |entry|
          puts "Timestamp: #{entry.timestamp}, Git Branch: #{entry.git_branch}, Git Commit: #{entry.git_commit}"
        end
      end
    end

    desc "table", "特定のテーブルに関するマイグレーション履歴を取得"
    option :table, required: true, desc: "テーブル名"
    option :output, required: false, desc: "HTML出力ファイル名"
    def table
      table_name = options[:table]
      result = MigrationHistory.filter(table_name)

      if options[:output]
        generate_html(result, options[:output])
      else
        result.each do |entry|
          puts "Timestamp: #{entry.timestamp}, Git Branch: #{entry.git_branch}, Git Commit: #{entry.git_commit}"
        end
      end
    end

    desc "column", "特定のカラムに関するマイグレーション履歴を取得"
    option :table, required: true, desc: "テーブル名"
    option :column, required: true, desc: "カラム名"
    option :output, required: false, desc: "HTML出力ファイル名"

    def column
      table_name = options[:table]
      column_name = options[:column]
      result = MigrationHistory.filter(table_name, column_name)

      if options[:output]
        generate_html(result, options[:output])
      else
        result.each do |entry|
          puts "Timestamp: #{entry.timestamp}, Git Branch: #{entry.git_branch}, Git Commit: #{entry.git_commit}"
        end
      end
    end

    private
      def generate_html(result, output_file)
        Formatter::HTMLFormatter.new.format(result)
        puts "HTMLファイルが #{output_file} に出力されました。"
      end
  end
end
