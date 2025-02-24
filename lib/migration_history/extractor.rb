require "parser/current"

class MigrationHistory::Extractor < Parser::AST::Processor
  attr_reader :current_class, :actions
  TABLE_DEFINITION_ADD_COLUMN_METHODS = %i(
    column primary_key timestamps
    blob tinyblob mediumblob longblob
    tinytext mediumtext longtext unsigned_integer unsigned_bigint
    unsigned_float unsigned_decimal bigserial bit bit_varying cidr citext daterange
    hstore inet interval int4range int8range jsonb ltree macaddr
    money numrange oid point line lseg box path polygon circle
    serial tsrange tstzrange tsvector uuid xml timestamptz enum
    bigint binary boolean date datetime decimal
    float integer json string text time timestamp virtual
  )

  def initialize
    @current_class = nil
    @actions = []
  end

  def on_class(node)
    class_name, _superclass, body = *node
    @current_class = class_name.children[1].to_s
    process(body)
  end

  def on_def(node)
    method_name, _args, body = *node
    @current_method = method_name
    if %i(up change).include?(method_name)
      process(body)
    end
    @current_method = nil
  end

  def on_send(node)
    return unless @current_method
    receiver, method_name, *args = *node
    return unless receiver.nil?

    case method_name
    when :create_table
      table_name = args.first.children.first
      options = extract_options(args[1])
      @actions << { action: :create_table, details: { table_name: table_name, options: options } }
    when :add_column
      table_name = args.first.children.first
      options = extract_options(args[1])
      @actions << { action: :add_column, details: { table_name: table_name, column_name: args[1].children.first, type: args[2].children.first, options: options } }
    end
  end

  def on_block(node)
    return unless @current_method
    send_node, args, body = *node
    _, method_name, *_ = *send_node

    table_name = send_node.children.try(:[], 2)&.children&.first
    table_var_name = args.children&.first&.children&.first

    return unless table_name && table_var_name

    case method_name
    when :create_table
      @actions << { action: :create_table, details: { table_name: table_name, options: {} } }
    end

    handle_table_block(body, table_name, table_var_name)
  end


  def extract_options(option_hash_node)
    return {} unless option_hash_node&.type == :hash

    option_hash_node.children.each_with_object({}) do |pair, hash|
      key, value = pair.children
      hash[key.children.first] = value.children.first
    end
  end

  private
    def handle_table_block(body, table_name, table_var_name)
      body.children.each do |child|
        next if child.nil? || child.is_a?(Symbol)
        next unless child.type == :send

        receiver, method_name, *args = *child
        next unless receiver&.type == :lvar && receiver.children.first == table_var_name
        if TABLE_DEFINITION_ADD_COLUMN_METHODS.include?(method_name)
          if method_name == :timestamps
            %i(created_at updated_at).each do |column_name|
              @actions << {
                action: :add_column,
                details: { table_name: table_name, column_name: column_name, type: :datetime, options: {} }
              }
            end
          else
            column_name = args[0]&.children&.first
            type = not_column_type_method?(method_name) ? args[1].children.first : method_name
            options = not_column_type_method?(method_name) ? extract_options(args[2]) : extract_options(args[1])

            next unless column_name
            @actions << {
              action: :add_column,
              details: { table_name: table_name, column_name: column_name, type: type, options: options }
            }
          end
        end
      end
    end

    def not_column_type_method?(method_name)
      %i(primary_key column).include?(method_name)
    end
end
