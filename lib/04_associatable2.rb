require_relative '03_associatable'
require 'byebug'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)

    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]

      through_foreign_key_sym = self.send(through_options.foreign_key)
      through_class = through_options.model_class
      through_instance = through_class.where(id: through_foreign_key_sym).first

      source_foreign_key_sym = through_instance.send(source_options.foreign_key)
      source_class = source_options.model_class
      source_instance = source_class.where(id: source_foreign_key_sym).first

    end

  end

end
