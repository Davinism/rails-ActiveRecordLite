require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    values = params.values
    params_with_question_marks = params.keys.map do |attribute|
      "#{attribute.to_s} = ?"
    end
    where_line = params_with_question_marks.join(" AND ")

    self.parse_all(DBConnection.execute(<<-SQL, params.values))
      SELECT
        *
      FROM #{self.table_name}
      WHERE #{where_line}
    SQL

  end

end

class SQLObject
  extend Searchable
end
