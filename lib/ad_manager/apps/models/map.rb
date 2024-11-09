# frozen_string_literal: true

class Map

  attr_accessor :id, :from_tb, :from_id, :refer_tb, :refer_id

  def initialize(map)
    @id = map['id']
    @from_tb = map['from_tb']
    @from_id = map['from_id']
    @refer_tb = map['refer_tb']
    @refer_id = map['refer_id']
  end
end
