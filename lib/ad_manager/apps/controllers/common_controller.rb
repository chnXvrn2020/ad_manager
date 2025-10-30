# frozen_string_literal: true

class CommonController

  # commonのデータのtypeを利用して呼び出す
  def get_type_menu(types)
    db = connect_to_db

    common = begin
      CommonService.instance.get_type_menu(db, types)
    rescue StandardError => e
      return e.message
    ensure
      db.close
    end

    model = []

    common.each do |hash|
      model << Common.new(hash)
    end

    model
  end

  # commonのリストを呼び出す
  def get_common_list(text, current_page = 1, keyword = nil)
    type = radio_to_type(text)

    return if type.nil?

    db = connect_to_db

    begin
      CommonService.instance.get_common_list(db, type, current_page, keyword)
    rescue StandardError => e
      e.message
    ensure
      db.close
    end
  end

  # commonの一つを呼び出す
  def get_one_common(id)
    db = connect_to_db

    data = begin
      CommonService.instance.get_one_common(db, id)
    rescue StandardError => e
      return e.message
    ensure
      db.close
    end

    return nil if data.empty?

    Common.new(data[0])
  end

  # commonを追加する
  def add_one_common(common)
    db = connect_to_db

    begin
      CommonService.instance.get_one_common(db, common)
    rescue StandardError => e
      e.message
    ensure
      db.close
    end
  end

  # commonを変更する
  def modify_one_common(common)
    db = connect_to_db

    begin
      CommonService.instance.modify_one_common(db, common)
    rescue StandardError => e
      e.message
    ensure
      db.close
    end
  end

  # commonを削除する
  def remove_one_common(id)
    db = connect_to_db

    begin
      CommonService.instance.remove_one_common(db, id)
    rescue StandardError => e
      e.message
    ensure
      db.close
    end
  end

end
