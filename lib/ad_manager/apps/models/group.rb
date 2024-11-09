# frozen_string_literal: true

class Group

  attr_accessor :id, :original, :original_name, :name, :use_yn,
                :insert_date, :update_date, :delete_date

  def initialize(group)
    @id = group['id']
    @original = group['original']
    @original_name = group['original_name']
    @name = group['name']
    @use_yn = group['use_yn']
    @insert_date = group['insert_date']
    @update_date = group['update_date']
    @delete_date = group['delete_date']
  end

end
