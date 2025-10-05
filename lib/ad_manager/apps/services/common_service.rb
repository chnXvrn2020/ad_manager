# frozen_string_literal: true

require 'singleton'
class CommonService
  include Singleton

  def get_type_menu(db, types)
    CommonMapper.instance.select_by_types(db, types)
  end

  def get_common_list(db, type, current_page, keyword)
    count = CommonMapper.instance.select_count_by_type(db, type, keyword)
    page = Page.new(count, current_page)
    common = CommonMapper.instance.select_by_type(db, type, page, keyword)

    model = []

    common.each do |hash|
      model << Common.new(hash)
    end

    { 'model' => model, 'page' => page }
  end

  def get_one_common(db, id)
    CommonMapper.instance.select_by_id(db, id)
  end

  def add_one_common(db, common)
    if CommonMapper.instance.check_duplicate_name(db, common)
      db.close
      return false
    end

    CommonMapper.instance.insert_common(db, common)
    true
  end

  def modify_one_common(db, common)
    if CommonMapper.instance.check_duplicate_name(db, common)
      return false
    end

    CommonMapper.instance.update_by_id(db, common)
    true
  end

  def remove_one_common(db, id)
    CommonMapper.instance.delete_by_id(db, id)
  end

end

BookService.instance
