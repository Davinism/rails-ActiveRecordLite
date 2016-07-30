require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    @query_arr ||= DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM #{self.table_name}
    SQL
    @query_arr.first.map(&:to_sym)
  end

  def self.finalize!
    self.columns.each do |column|
      define_method("#{column}") do
        attributes[column]
      end

      define_method("#{column}=") do |val|
        attributes[column] = val
      end

    end

  end

  def self.table_name=(table_name)
    @table = table_name
  end

  def self.table_name
    @table ||= "#{self.to_s.tableize}"
  end

  def self.all
    self.parse_all(DBConnection.execute(<<-SQL))
      SELECT
        *
      FROM #{self.table_name}
    SQL
  end

  def self.parse_all(results)
    results.map do |attributes|
      self.new(attributes)
    end
  end

  def self.find(id)
    self.parse_all(DBConnection.execute(<<-SQL, [id])).first
      SELECT
        *
      FROM #{self.table_name}
      WHERE #{self.table_name}.id = ?
    SQL
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      unless self.class.columns.include?(attr_name.to_sym)
        raise "unknown attribute '#{attr_name}'"
      end

      self.class.finalize!
      self.send("#{attr_name}=", value)

    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    results_arr = []
    self.class.columns.each do |column|
      results_arr << self.send(column)
    end
    results_arr
  end

  def insert
    col_names = self.class.columns.map(&:to_s).join(", ")
    question_marks = ["?"] * col_names.split(", ").length

    DBConnection.execute(<<-SQL, self.attribute_values)
      INSERT INTO #{self.class.table_name} (#{col_names})
      VALUES (#{question_marks.join(", ")})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    col_names_with_equal = self.class.columns.map do |column|
      "#{column.to_s} = ?"
    end
    set_line = col_names_with_equal.join(", ")

    DBConnection.execute(<<-SQL, [*self.attribute_values, self.id])
      UPDATE #{self.class.table_name}
      SET #{set_line}
      WHERE
        id = ?
    SQL
  end

  def save
    self.id.nil? ? insert : update
  end
end
