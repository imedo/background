module ActiveRecord
  class Base
    def clone_for_background
      dup
    end
  end
end
