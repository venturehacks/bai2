
module Bai2
  private

  # Helps define methods that simply read from a hash ivar. For example, imagine
  # this class:
  #
  #   class Person
  #     def initialize
  #       @info = {
  #         first_name: 'John',
  #         last_name:  'Smith',
  #       }
  #     end
  #     attr_reader_from_ivar_hash :@info, :first_name, :last_name
  #   end
  #
  # That last statement will automagically create methods `.first_name`, and
  # `.last_name` on `Person`, which saves a whole bunch of typing :).
  #
  module AttrReaderFromIvarHash

    def attr_reader_from_ivar_hash(ivar, *keys)
      keys.each do |key|
        define_method(key) do
          (instance_variable_get(ivar) || {})[key]
        end
      end
    end
  end
end
