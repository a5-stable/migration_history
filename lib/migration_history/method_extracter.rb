# frozen_string_literal: true

require "parser/current"

class MigrationHistory::MigrationMethodExtractor < Parser::AST::Processor
  attr_reader :methods, :current_class

  def initialize
    @methods = []
    @current_class = nil
  end

  def on_class(node)
    class_name, _superclass, body = *node
    @current_class = class_name.children.last.to_s
    process(body)
  end

  def on_send(node)
    method_name = node.children[1]
    if @current_class
      @methods << method_name
    end
    super
  end
end
