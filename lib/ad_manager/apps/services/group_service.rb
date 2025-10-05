# frozen_string_literal: true

require 'singleton'

class GroupService
  include Singleton

  def get_group_list_with_count(db, keyword, status_id, current_page)
    count = GroupMapper.instance.select_all_count(db, keyword, status_id)
    page = Page.new(count, current_page)
    group = GroupMapper.instance.select_all(db, page, keyword, status_id)

    model = []

    group.each do |hash|
      model << Group.new(hash)
    end

    { 'model' => model, 'page' => page }
  end

  def get_book_group_list_with_count(db, type, keyword, status, current_page)
    count = GroupMapper.instance.select_book_group_list_count(db, type, keyword, status)
    page = Page.new(count, current_page)
    book_group = GroupMapper.instance.select_book_group_list(db, type, page, keyword, status)

    model = []

    book_group.each do |hash|
      model << Group.new(hash)
    end

    { 'model' => model, 'page' => page }
  end

  def get_group_status_info(db, id)
    anime_data = GroupMapper.instance.select_anime_status_list_by_group_id(db, id)
    book_data = GroupMapper.instance.select_book_status_list_by_group_id(db, id)
    book_count = BookMapper.instance.select_all_book_count_by_group_id(db, id)

    anime = []
    book = []

    anime_data.each do |hash|
      anime << Anime.new(hash)
    end

    book_data.each do |hash|
      book << Book.new(hash)
    end

    { 'anime' => anime, 'book' => book, 'book_count' => book_count }
  end

  def find_group_on_map(db, common, id)
    type = case common.name
           when I18n.t('home.anime')
             'tb_anime'
             else
             'tb_book'
           end

    MapMapper.instance.select_group_mapping(db, type, id)
  end

  def get_group_list(db, id, param)
    group = GroupMapper.instance.select_list(db, id, param)

    model = []

    group.each do |hash|
      model << Group.new(hash)
    end

    model
  end

  def get_group_list_by_content_id(db, id, keyword)
    group = GroupMapper.instance.select_by_content_id(db, id, keyword)

    model = []

    group.each do |hash|
      model << Group.new(hash)
    end

    model
  end

  def get_selected_group_list(db, id)
    group = GroupMapper.instance.select_selected_group_list(db, id)

    model = []

    group.each do |hash|
      model << Group.new(hash)
    end

    model
  end

  def add_group(db, group)
    if GroupMapper.instance.check_duplicate_name(db, group)
      return false
    end

    GroupMapper.instance.insert_group(db, group)
    true
  end

  def get_one_group(db, id)
    data = GroupMapper.instance.select_by_id(db, id)
    Group.new(data[0])
  end

  def modify_one_group(db, group)
    if GroupMapper.instance.check_duplicate_name(db, group)
      return false
    end

    GroupMapper.instance.update_group(db, group)
    true
  end

  def remove_one_group(db, id)
    MapMapper.instance.delete_group_mapping(db, id)
    GroupMapper.instance.delete_group(db, id)
  end

  def set_mapping_group(db, id, group_id)
    param = {
      from_tb: 'tb_content',
      from_id: id,
      refer_tb: 'tb_group',
      refer_id: group_id
    }

    map = create_map(param)

    MapMapper.instance.insert_mapping(db, map)
  end

  def remove_mapping_group(db, id, group_id)
    param = {
      from_tb: 'tb_content',
      from_id: id,
      refer_tb: 'tb_group',
      refer_id: group_id
    }

    map = create_map(param)

    MapMapper.instance.delete_one_mapping(db, map)
  end

end

GroupService.instance
