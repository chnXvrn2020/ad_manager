# frozen_string_literal: true

require 'singleton'

class BookService
  include Singleton

  def get_book_list_with_count(db, type, keyword, status, current_page)
    count = BookMapper.instance.select_all_count(db, type, keyword, status)
    page = Page.new(count, current_page)
    book = BookMapper.instance.select_all(db, type, page, keyword, status)

    model = []

    book.each do |hash|
      model << Book.new(hash)
    end

    { 'model' => model, 'page' => page }
  end

  def modify_book(db, book)
    return false if BookMapper.instance.check_duplicate_name(db, book)

    BookMapper.instance.update_book(db, book)
  end

  def remove_book(db, id)
    BookMapper.instance.delete_book(db, id)
  end

  def get_book_list(db, type, group_id, keyword)
    BookMapper.instance.select_book_list(db, type, group_id, keyword)
  end

  def get_book_count_by_group_id(db, type, group_id)
    BookMapper.instance.select_book_count_by_group_id(db, type, group_id)
  end

  def get_unselected_book_list(db, type, group_id, keyword)
    BookMapper.instance.select_unselected_book_list(db, type, group_id, keyword)
  end

  def get_book_by_id(db, id)
    BookMapper.instance.select_book_by_id(db, id)
  end

  def get_book_info_by_id(db, id)
    book = BookMapper.instance.select_book_by_id(db, id)
    status = BookMapper.instance.select_book_status(db, id)

    return { 'book' => Book.new(book[0]), 'status' => nil } if status.empty?

    { 'book' => Book.new(book[0]), 'status' => Book.new(status[0]) }
  end

  def complete_read_book(db, id, completion_date)
    BookMapper.instance.insert_book_complete(db, id, completion_date)
    BookMapper.instance.select_book_status(db, id)
  end

  def get_completed_book_count_by_group_id(db, type, group_id)
    BookMapper.instance.select_completed_book_count_by_group_id(db, type, group_id)
  end

  def add_book(db, book)
    duplicate_check = BookMapper.instance.check_duplicate_name(db, book)

    return false if duplicate_check

    last_id = BookMapper.instance.insert_book(db, book)

    return nil if last_id.nil?

    last_id
  end

  def set_mapping_book(db, group_id, book_id)
    param = {
      from_tb: 'tb_group',
      from_id: group_id,
      refer_tb: 'tb_book',
      refer_id: book_id
    }

    map = create_map(param)

    MapMapper.instance.insert_mapping(db, map)
  end

  def remove_mapping_book(db, group_id, book_id)
    param = {
      from_tb: 'tb_group',
      from_id: group_id,
      refer_tb: 'tb_book',
      refer_id: book_id
    }

    map = create_map(param)

    MapMapper.instance.delete_one_mapping(db, map)
  end

  def recommend_book(db, type_id)
    book_data = BookMapper.instance.book_recommend_by_type_id(db, type_id)

    book = []

    book_data.each do |data|
      book << Group.new(data)
    end

    loop do
      rand_book = book.sample
      status_count = BookMapper.instance.select_book_status_count_by_group_id(db, rand_book.id)

      if status_count <= 0
        temp_content = MapMapper.instance.select_content_mapping(db, rand_book.id)

        recommend_content = ContentMapper.instance.select_by_id(db, temp_content[0]['content_id'])
        content = Content.new(recommend_content[0])

        recommend = {
          'content_id' => content.id,
          'book_content_data' => content.name,
          'group_id' => rand_book.id,
          'book_group_data' => rand_book.name
        }

        return recommend
      end
    end
  end

end

BookService.instance
