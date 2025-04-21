# frozen_string_literal: true

class GroupController

  def get_group_list(id = nil, param = nil)
    db = connect_to_db
    group = GroupMapper.instance.select_list(db, id, param)
    db.close

    model = []

    group.each do |hash|
      model << Group.new(hash)
    end

    model

  end

  def get_group_list_by_content_id(id, keyword = nil)
    db = connect_to_db
    group = GroupMapper.instance.select_by_content_id(db, id, keyword)
    db.close

    model = []

    group.each do |hash|
      model << Group.new(hash)
    end

    model
  end

  def get_group_list_with_count(current_page = 1, keyword = nil, status_id = nil)
    db = connect_to_db
    count = GroupMapper.instance.select_all_count(db, keyword, status_id)
    page = Page.new(count, current_page)
    group = GroupMapper.instance.select_all(db, page, keyword, status_id)
    db.close

    model = []

    group.each do |hash|
      model << Group.new(hash)
    end

    { 'model' => model, 'page' => page }
  end

  def get_selected_group_list(id)
    db = connect_to_db
    group = GroupMapper.instance.select_selected_group_list(db, id)
    db.close

    model = []

    group.each do |hash|
      model << Group.new(hash)
    end

    model
  end

  def add_group(group)
    db = connect_to_db

    if GroupMapper.instance.check_duplicate_name(db, group)
      db.close
      return false
    end

    GroupMapper.instance.insert_group(db, group)
    db.close

    true

  end

  def get_one_group(id)
    db = connect_to_db
    data = GroupMapper.instance.select_by_id(db, id)
    db.close

    Group.new(data[0])
  end

  def get_book_group_list_with_count(type, current_page = 1, keyword = nil, status = nil)
    db = connect_to_db
    count = GroupMapper.instance.select_book_group_list_count(db, type, keyword, status)
    page = Page.new(count, current_page)
    book_group = GroupMapper.instance.select_book_group_list(db, type, page, keyword, status)
    db.close

    model = []

    book_group.each do |hash|
      model << Group.new(hash)
    end

    { 'model' => model, 'page' => page }
  end

  def modify_one_group(group)
    db = connect_to_db

    if GroupMapper.instance.check_duplicate_name(db, group)
      db.close
      return false
    end

    GroupMapper.instance.update_group(db, group)
    db.close

    true
  end

  def remove_one_group(id)
    db = connect_to_db
    MapMapper.instance.delete_group_mapping(db, id)
    GroupMapper.instance.delete_group(db, id)
    db.close
  end

  def set_mapping_group(id, group_id)
    from_tb = 'tb_content'
    refer_tb = 'tb_group'

    map = Map.new({'from_tb' => from_tb,
                   'from_id' => id,
                   'refer_tb' => refer_tb,
                   'refer_id' => group_id})

    db = connect_to_db
    MapMapper.instance.insert_mapping(db, map)
    db.close
  end

  def remove_mapping_group(id, group_id)
    from_tb = 'tb_content'
    refer_tb = 'tb_group'

    map = Map.new({'from_tb' => from_tb,
                   'from_id' => id,
                   'refer_tb' => refer_tb,
                   'refer_id' => group_id})

    db = connect_to_db
    MapMapper.instance.delete_one_mapping(db, map)
    db.close
  end
  
  def find_group_on_map(common, id)
    type = case common.name
           when I18n.t('home.anime')
             'tb_anime'
             else
             'tb_book'
           end

    db = connect_to_db
    data = MapMapper.instance.select_group_mapping(db, type, id)
    db.close

    data
  end

  def recommend_anime_by_content_id(content_id)
    db = connect_to_db
    data = GroupMapper.instance.select_group_list_by_content_id(db, content_id)
    db.close

    model = []

    data.each do |hash|
      model << Group.new(hash)
    end

    model
  end

  def recommend_book(type_id)
    db = connect_to_db
    data = BookMapper.instance.book_recommend_by_type_id(db, type_id)
    db.close

    model = []

    data.each do |book|
      model << Group.new(book)
    end

    model
  end

  def get_group_anime_status(group_id)
    db = connect_to_db
    data = GroupMapper.instance.select_anime_status_list_by_group_id(db, group_id)
    db.close

    anime = []

    data.each do |hash|
      anime << Anime.new(hash)
    end

    anime
  end

  def get_group_book_status(group_id)
    db = connect_to_db
    data = GroupMapper.instance.select_book_status_list_by_group_id(db, group_id)
    db.close

    book = []

    data.each do |hash|
      book << Anime.new(hash)
    end

    book
  end

end
