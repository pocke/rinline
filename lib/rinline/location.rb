module Rinline
  class Location
    def initialize(first_index, last_index)
      @first_index = first_index
      @last_index = last_index
    end

    attr_reader :first_index, :last_index

    def size
      last_index - first_index + 1
    end
  end
end
