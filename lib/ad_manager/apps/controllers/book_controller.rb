# frozen_string_literal: true

class BookController

  # 書籍情報をリストとして呼び出す
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

  # 書籍のカウントを呼び出す
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

  # 未選択書籍のリストを呼び出す
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

  # 書籍をIDで呼び出す
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

  # 書籍情報をIDで呼び出す
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

  # 書籍をカウントとともに呼び出す
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

  # コンプリ書籍のカウントを呼び出す
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

  # 書籍情報を追加する
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

  # 書籍情報を変更する
  def modify_book(book)
    db = connect_to_db

    begin
      db.transaction

      result = BookService.instance.modify_book(db, book)
      return false unless result

      # 画像の変更
      # 画像が削除された場合はファイルを削除する
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

  # 書籍情報を削除する
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

  # 書籍をグループに紐づける
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

  # 書籍をグループから削除する
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

  # 完読した書籍を追加する
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

  # 書籍を推薦する
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
