# frozen_string_literal: true

class Content

  attr_accessor :id, :name, :use_yn,
                :insert_date, :update_date, :delete_date

  def initialize(content)
    @id = content['id']
    @name = content['name']
    @use_yn = content['use_yn']
    @insert_date = content['insert_date']
    @update_date = content['update_date']
    @delete_date = content['delete_date']
  end
end
