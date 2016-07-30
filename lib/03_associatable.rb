require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.constantize
  end

  def table_name
    class_name.to_s.underscore + "s"
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    options.keys.each do |method_symbol|
      self.send("#{method_symbol.to_s}=", options[method_symbol])
    end

    self.foreign_key ||= "#{name.to_s}_id".to_sym
    self.class_name ||= name.to_s.camelcase
    self.primary_key ||= :id
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    options.keys.each do |method_symbol|
      self.send("#{method_symbol.to_s}=", options[method_symbol])
    end

    self.foreign_key ||= "#{self_class_name.to_s.underscore}_id".to_sym
    self.class_name ||= name.to_s.camelcase.singularize
    self.primary_key ||= :id
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, association_options = {})
    # options = BelongsToOptions.new(name, association_options)
    #
    # define_method(name) do
    #   foreign_key_sym = self.send(options.foreign_key)
    #   target_class = options.model_class
    #   target_class.where(id: foreign_key_sym).first
    # end

    assoc_options
    options = BelongsToOptions.new(name, association_options)
    @assoc_options[name] = options

    define_method(name) do
      foreign_key_sym = self.send(options.foreign_key)
      target_class = options.model_class
      target_class.where(id: foreign_key_sym).first
    end

  end

  def has_many(name, association_options = {})
    options = HasManyOptions.new(name, self, association_options)

    define_method(name) do
      target_class = options.model_class
      target_class.where(options.foreign_key => self.id)
    end
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
    @assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
end
