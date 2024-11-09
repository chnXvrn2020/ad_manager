# frozen_string_literal: true

class Common

  attr_accessor :id, :type, :name, :use_yn,
                :insert_date, :update_date, :delete_date

  def initialize(common)
    @id = common['id']
    @type = common['type']
    @name = common['name']
    @use_yn = common['use_yn']
    @insert_date = common['insert_date']
    @update_date = common['update_date']
    @delete_date = common['delete_date']
  end

end
