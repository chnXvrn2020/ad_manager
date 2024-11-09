# frozen_string_literal: true

class Files

  attr_accessor :id, :refer_tb, :refer_id, :file_name,
                :use_yn, :insert_date, :update_date, :delete_date

  def initialize(files)
    @id = files['id']
    @refer_tb = files['refer_tb']
    @refer_id = files['refer_id']
    @file_name = files['file_name']
    @use_yn = files['use_yn']
    @insert_date = files['insert_date']
    @update_date = files['update_date']
    @delete_date = files['delete_date']
  end
end
