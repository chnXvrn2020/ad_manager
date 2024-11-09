# frozen_string_literal: true

class Book

  attr_accessor :id, :type, :name, :publisher, :created_date,
                :use_yn, :insert_date, :update_date, :delete_date,
                :completion_date, :status

  def initialize(anime)
    @id = anime['id']
    @type = anime['type']
    @name = anime['name']
    @publisher = anime['publisher']
    @created_date = anime['created_date']
    @use_yn = anime['use_yn']
    @insert_date = anime['insert_date']
    @update_date = anime['update_date']
    @delete_date = anime['delete_date']

    @completion_date = anime['completion_date']
    @status = anime['status']
  end

end
