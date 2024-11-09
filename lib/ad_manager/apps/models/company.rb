# frozen_string_literal: true

class Company

  attr_accessor :id, :type, :name, :parent_id, :current_yn,
                :use_yn, :insert_date, :update_date, :delete_date

  def initialize(company)
    @id = company['id']
    @type = company['type']
    @name = company['name']
    @parent_id = company['parent_id']
    @current_yn = company['current_yn']
    @use_yn = company['use_yn']
    @insert_date = company['insert_date']
    @update_date = company['update_date']
    @delete_date = company['delete_date']
  end

end
