require 'thor'
require 'erb'

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
      template = <<-HTML
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Migration History</title>
        <style>
          table {
            width: 100%;
            border-collapse: collapse;
          }
          th, td {
            padding: 8px;
            text-align: left;
            border: 1px solid #ddd;
          }
          th {
            background-color: #f2f2f2;
          }
        </style>
      </head>
      <body>
        <h1>Migration History</h1>
        <table>
          <thead>
            <tr>
              <th>Timestamp</th>
              <th>Git Branch</th>
              <th>Git Commit</th>
            </tr>
          </thead>
          <tbody>
            <% result.each do |entry| %>
              <tr>
                <td><%= entry.timestamp %></td>
                <td><%= entry.git_branch %></td>
                <td><%= entry.git_commit %></td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </body>
      </html>
      HTML

      # ERBテンプレートをレンダリング
      erb_template = ERB.new(template)
      html_output = erb_template.result(binding)

      # HTMLを指定されたファイルに書き込む
      File.open(output_file, 'w') do |file|
        file.write(html_output)
      end

      puts "HTMLファイルが #{output_file} に出力されました。"
    end
  end
end
