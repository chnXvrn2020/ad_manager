# frozen_string_literal: true

class CommonController

  def get_common_menu(type)

    db = connect_to_db
    common = CommonMapper.instance.select_by_type(db, type)
    db.close

    model = []

    common.each do |hash|
      model << Common.new(hash)
    end

    model
  end

  def get_type_menu(types)
    db = connect_to_db
    common = CommonMapper.instance.select_by_types(db, types)
    db.close

    model = []

    common.each do |hash|
      model << Common.new(hash)
    end

    model
  end

  def get_common_list(text, current_page = 1, keyword = nil)
    type = radio_to_type(text)

    return if type.nil?

    db = connect_to_db
    count = CommonMapper.instance.select_count_by_type(db, type, keyword)
    page = Page.new(count, current_page)
    common = CommonMapper.instance.select_by_type(db, type, page, keyword)
    db.close

    model = []

    common.each do |hash|
      model << Common.new(hash)
    end

    { 'model' => model, 'page' => page }
  end

  def get_one_common(id)
    db = connect_to_db
    data = CommonMapper.instance.select_by_id(db, id)
    db.close

    return if data.empty?

    Common.new(data[0])
  end

  def add_one_common(common)
    db = connect_to_db

    if CommonMapper.instance.check_duplicate_name(db, common)
      db.close
      return false
    end

    CommonMapper.instance.insert_common(db, common)
    db.close

    true
  end

  def modify_one_common(common)
    db = connect_to_db

    if CommonMapper.instance.check_duplicate_name(db, common)
      db.close
      return false
    end

    CommonMapper.instance.update_by_id(db, common)
    db.close

    true
  end

  def remove_one_common(id)
    db = connect_to_db
    CommonMapper.instance.delete_by_id(db, id)
    db.close
  end

end
