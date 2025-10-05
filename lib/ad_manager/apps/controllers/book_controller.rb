# frozen_string_literal: true

class BookController

  def get_book_list(type, group_id, keyword = nil)
    db = connect_to_db

    data = begin
             BookService.instance.get_book_list(db, type, group_id, keyword)
    rescue StandardError => e
             return e.message
    ensure
             db.close
    end

    book = []

    data.each do |hash|
      book << Book.new(hash)
    end

    book
  end

  def get_book_count_by_group_id(type, group_id)
    db = connect_to_db

    begin
      BookService.instance.get_book_count_by_group_id(db, type, group_id)
    rescue StandardError => e
      e.message
    ensure
      db.close
    end
  end

  def get_unselected_book_list(type, group_id, keyword = nil)
    db = connect_to_db

    data = begin
             BookService.instance.get_unselected_book_list(db, type, group_id, keyword)
    rescue StandardError => e
             return e.message
    ensure
             db.close
    end

    book = []

    data.each do |hash|
      book << Book.new(hash)
    end

    book
  end

  def get_book_by_id(id)
    db = connect_to_db
    data = begin
             BookService.instance.get_book_by_id(db, id)
    rescue StandardError => e
             return e.message
    ensure
             db.close
    end

    Book.new(data[0])
  end

  def get_book_info_by_id(type, id)
    db = connect_to_db

    begin
      book_info = BookService.instance.get_book_info_by_id(db, id)
      book_file = FileService.instance.get_image_file(db, type, id)

      book_info.merge!("file" => book_file)
    rescue StandardError => e
      return e.message
    ensure
      db.close
    end

    book_info
  end

  def get_book_list_with_count(type, current_page = 1, keyword = nil, status = nil)
    db = connect_to_db

    begin
      BookService.instance.get_book_list_with_count(db, type, keyword, status, current_page)
    rescue StandardError => e
      e.message
    ensure
      db.close
    end
  end

  def get_completed_book_count_by_group_id(type, group_id)
    db = connect_to_db

    begin
      BookService.instance.get_completed_book_count_by_group_id(db, type, group_id)
    rescue StandardError => e
      e.message
    ensure
      db.close
    end
  end

  def add_book(param)
    db = connect_to_db

    begin
      db.transaction
      last_id = BookMapper.instance.insert_book(db, param[:book])
      raise if last_id.nil?

      file = file_upload(param[:img_file_name], param[:content_type], last_id)

      FileService.instance.add_image_file(db, Files.new(file)) unless file.nil?
      BookService.instance.set_mapping_book(db, param[:group_id], last_id)
      db.commit
    rescue StandardError => e
      db.rollback
      File.delete("#{img_path}#{file["file_name"]}") unless file.nil?
      return e.message
    ensure
      db.close
    end

    true
  end

  def modify_book(book)
    db = connect_to_db

    begin
      db.transaction

      result = BookService.instance.modify_book(db, book)
      return false unless result

      if img['img_del'] == 'Y'
        file = {}

        file['refer_tb'] = img['content_type']
        file['refer_id'] = img['content_id']

        FileService.instance.delete_image_file(db, Files.new(file))
      else
        FileService.instance.modify_image_file(db, img)
      end

      db.commit
    rescue StandardError => e
      db.rollback
      return e.message
    ensure
      db.close
    end

    true
  end

  def remove_book(id, file)
    db = connect_to_db

    begin
      db.transaction
      BookService.instance.remove_book(db, id)
      FileService.instance.delete_image_file(db, file)
      db.commit
    rescue StandardError => e
      db.rollback
      return e.message
    ensure
      db.close
    end

    true
  end

  def set_mapping_book(group_id, book_id)
    db = connect_to_db

    begin
      BookService.instance.set_mapping_book(db, group_id, book_id)
    rescue StandardError => e
      return e.message
    ensure
      db.close
    end

    true
  end

  def remove_mapping_book(group_id, book_id)
    db = connect_to_db

    begin
      BookService.instance.remove_mapping_book(db, group_id, book_id)
    rescue StandardError => e
      return e.message
    ensure
      db.close
    end

    true
  end

  def complete_read_book(id, completion_date = nil)
    db = connect_to_db

    data = begin
             BookService.instance.complete_read_book(db, id, completion_date)
    rescue StandardError => e
             return e.message
    ensure
             db.close
    end

    return nil if data.empty?

    Book.new(data[0])
  end

  def recommend_book(type_id)
    db = connect_to_db

    begin
      BookService.instance.recommend_book(db, type_id)
    rescue StandardError => e
      e.message
    ensure
      db.close
    end
  end

end
