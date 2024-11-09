# frozen_string_literal: true

class ContentController

  def get_content_list(current_page = 1, keyword = nil, status = nil)
    db = connect_to_db
    count = ContentMapper.instance.select_content_count(db, keyword, status)
    page = Page.new(count, current_page)
    content = ContentMapper.instance.select_content(db, page, keyword, status)
    db.close

    model = []

    content.each do |hash|
      model << Content.new(hash)
    end

    { 'model' => model, 'page' => page }
  end

  def add_content(name)
    db = connect_to_db

    if ContentMapper.instance.check_duplicate_name(db, name)
      db.close
      return nil
    end

    last_id = ContentMapper.instance.insert_content(db, name)
    db.close

    last_id
  end

  def get_one_content(id)
    db = connect_to_db
    data = ContentMapper.instance.select_by_id(db, id)
    db.close

    Content.new(data[0])
  end

  def modify_content(content)
    db = connect_to_db

    if ContentMapper.instance.check_duplicate_name(db, content.name)
      db.close
      return false
    end

    ContentMapper.instance.update_content(db, content)
    db.close

    true
  end

  def remove_content(id)
    db = connect_to_db
    ContentMapper.instance.delete_content(db, id)
    db.close
  end

  def find_content_on_map(id)

    db = connect_to_db
    data = MapMapper.instance.select_content_mapping(db, id)
    db.close

    data

  end

  def recommend_anime
    db = connect_to_db
    data = ContentMapper.instance.select_all_content_with_group(db)
    db.close

    model = []

    data.each do |content|
      model << Content.new(content)
    end

    model
  end

end
