# frozen_string_literal: true

class BookController

  def get_book_list(type, group_id, keyword = nil)
    db = connect_to_db
    data = BookMapper.instance.select_book_list(db, type, group_id, keyword)
    db.close

    book = []

    data.each do |hash|
      book << Book.new(hash)
    end

    book

  end

  def get_book_count_by_group_id(type, group_id)
    db = connect_to_db
    count = BookMapper.instance.select_book_count_by_group_id(db, type, group_id)
    db.close

    count
  end

  def get_unselected_book_list(type, group_id, keyword = nil)
    db = connect_to_db
    data = BookMapper.instance.select_unselected_book_list(db, type, group_id, keyword)
    db.close

    book = []

    data.each do |hash|
      book << Book.new(hash)
    end

    book
  end

  def get_book_by_id(id)
    db = connect_to_db
    data = BookMapper.instance.select_book_by_id(db, id)
    db.close

    Book.new(data[0])
  end

  def get_book_list_with_count(type, current_page = 1, keyword = nil, status = nil)
    db = connect_to_db
    count = BookMapper.instance.select_all_count(db, type, keyword, status)
    page = Page.new(count, current_page)
    book = BookMapper.instance.select_all(db, type, page, keyword, status)
    db.close

    model = []

    book.each do |hash|
      model << Book.new(hash)
    end

    { 'model' => model, 'page' => page }
  end

  def get_book_status(id)
    db = connect_to_db
    data = BookMapper.instance.select_book_status(db, id)
    db.close

    return nil if data.empty?

    Book.new(data[0])
  end

  def get_completed_book_count_by_group_id(type, group_id)
    db = connect_to_db
    count = BookMapper.instance.select_completed_book_count_by_group_id(db, type, group_id)
    db.close

    count
  end

  def add_book(book)
    db = connect_to_db

    if BookMapper.instance.check_duplicate_name(db, book)
      db.close
      return nil
    end

    last_id = BookMapper.instance.insert_book(db, book)

    db.close

    last_id
  end

  def modify_book(book)
    db = connect_to_db

    if BookMapper.instance.check_duplicate_name(db, book)
      db.close
      return false
    end

    BookMapper.instance.update_book(db, book)
    db.close

    true
  end

  def remove_book(id)
    db = connect_to_db
    BookMapper.instance.delete_book(db, id)
    db.close
  end

  def set_mapping_book(group_id, book_id)
    from_tb = 'tb_group'
    refer_tb = 'tb_book'

    map = Map.new({'from_tb' => from_tb,
                   'from_id' => group_id,
                   'refer_tb' => refer_tb,
                   'refer_id' => book_id})

    db = connect_to_db
    MapMapper.instance.insert_mapping(db, map)
    db.close
  end

  def set_remove_book(group_id, book_id)
    from_tb = 'tb_group'
    refer_tb = 'tb_book'

    map = Map.new({'from_tb' => from_tb,
                   'from_id' => group_id,
                   'refer_tb' => refer_tb,
                   'refer_id' => book_id})

    db = connect_to_db
    MapMapper.instance.delete_one_mapping(db, map)
    db.close
  end

  def complete_read_book(id, completion_date = nil)
    db = connect_to_db
    BookMapper.instance.insert_book_complete(db, id, completion_date)
    db.close
  end

  def get_current_status(group_id)
    db = connect_to_db
    count = BookMapper.instance.select_book_status_count_by_group_id(db, group_id)
    db.close

    count
  end

  def get_all_book_count(group_id)
    db = connect_to_db
    count = BookMapper.instance.select_all_book_count_by_group_id(db, group_id)
    db.close

    count
  end

end
