# frozen_string_literal: true

class ContentController

  # コンテンツのリストを呼び出す
  def get_content_list(current_page = 1, keyword = nil, status = nil)
    db = connect_to_db

    begin
      ContentService.instance.get_content_list(db, keyword, status, current_page)
    rescue StandardError => e
      e.message
    ensure
      db.close
    end
  end

  # コンテンツの追加
  def add_content(name)
    db = connect_to_db

    begin
      ContentService.instance.add_content(db, name)
    rescue StandardError => e
      e.message
    ensure
      db.close
    end
  end

  # 一つのコンテンツを呼び出す
  def get_one_content(id)
    db = connect_to_db

    begin
      data = ContentService.instance.get_one_content(db, id)
    rescue StandardError => e
      return e.message
    ensure
      db.close
    end

    Content.new(data[0])
  end

  # コンテンツの情報を変更する
  def modify_content(content)
    db = connect_to_db

    begin
      ContentService.instance.modify_content(db, content)
    rescue StandardError => e
      e.message
    ensure
      db.close
    end
  end

  # コンテンツを削除する
  def remove_content(id)
    db = connect_to_db

    begin
      ContentService.instance.remove_content(db, id)
    rescue StandardError => e
      return e.message
    ensure
      db.close
    end

    true
  end

  # マップを利用してコンテンツを検索する
  def find_content_on_map(id)
    db = connect_to_db

    begin
      ContentService.instance.find_content_on_map(db, id)
    rescue StandardError => e
      e.message
    ensure
      db.close
    end
  end

end
