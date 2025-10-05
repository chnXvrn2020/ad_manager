# frozen_string_literal: true

require 'singleton'

class ContentService
  include Singleton

  def get_content_list(db, keyword, status, current_page)
    count = ContentMapper.instance.select_content_count(db, keyword, status)
    page = Page.new(count, current_page)
    content = ContentMapper.instance.select_content(db, page, keyword, status)

    model = []

    content.each do |hash|
      model << Content.new(hash)
    end

    { 'model' => model, 'page' => page }
  end

  def find_content_on_map(db, id)
    MapMapper.instance.select_content_mapping(db, id)
  end

  def add_content(db, name)
    if ContentMapper.instance.check_duplicate_name(db, name)
      return nil
    end

    ContentMapper.instance.insert_content(db, name)
  end

  def get_one_content(db, id)
    ContentMapper.instance.select_by_id(db, id)
  end

  def modify_content(db, content)
    if ContentMapper.instance.check_duplicate_name(db, content.name)
      return false
    end

    ContentMapper.instance.update_content(db, content)
    true
  end

  def remove_content(db, id)
    ContentMapper.instance.delete_content(db, id)
  end

end

ContentService.instance
