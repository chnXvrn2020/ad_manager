# frozen_string_literal: true

class GroupController

  def get_group_list(id = nil, param = nil)
    db = connect_to_db

    begin
      GroupService.instance.get_group_list(db, id, param)
    rescue StandardError => e
      e.message
    ensure
      db.close
    end
  end

  def get_group_list_by_content_id(id, keyword = nil)
    db = connect_to_db

    begin
      GroupService.instance.get_group_list_by_content_id(db, id, keyword)
    rescue StandardError => e
      e.message
    ensure
      db.close
    end
  end

  def get_group_list_with_count(current_page = 1, keyword = nil, status_id = nil)
    db = connect_to_db

    begin
      GroupService.instance.get_group_list_with_count(db, keyword, status_id, current_page)
    rescue StandardError => e
      e.message
    ensure
      db.close
    end
  end

  def get_selected_group_list(id)
    db = connect_to_db

    begin
      GroupService.instance.get_selected_group_list(db, id)
    rescue StandardError => e
      e.message
    ensure
      db.close
    end
  end

  def add_group(group)
    db = connect_to_db

    begin
      GroupService.instance.add_group(db, group)
    rescue StandardError => e
      e.message
    ensure
      db.close
    end

  end

  def get_one_group(id)
    db = connect_to_db

    begin
      GroupService.instance.get_one_group(db, id)
    rescue StandardError => e
      e.message
    ensure
      db.close
    end
  end

  def get_book_group_list_with_count(type, current_page = 1, keyword = nil, status = nil)
    db = connect_to_db

    begin
      GroupService.instance.get_book_group_list_with_count(db, type, keyword, status, current_page)
    rescue StandardError => e
      e.message
    ensure
      db.close
    end
  end

  def modify_one_group(group)
    db = connect_to_db

    begin
      GroupService.instance.modify_one_group(db, group)
    rescue StandardError => e
      e.message
    ensure
      db.close
    end
  end

  def remove_one_group(id)
    db = connect_to_db

    begin
      db.transaction
      GroupService.instance.remove_one_group(db, id)
      db.commit
    rescue StandardError => e
      db.rollback
      return e.message
    ensure
      db.close
    end

    true
  end

  def set_mapping_group(id, group_id)
    db = connect_to_db

    begin
      GroupService.instance.set_mapping_group(db, id, group_id)
    rescue StandardError => e
      return e.message
    ensure
      db.close
    end

    true
  end

  def remove_mapping_group(id, group_id)
    db = connect_to_db

    begin
      GroupService.instance.remove_mapping_group(db, id, group_id)
    rescue StandardError => e
      return e.message
    ensure
      db.close
    end

    true
  end

  def find_group_on_map(common, id)
    db = connect_to_db

    begin
      GroupService.instance.find_group_on_map(db, common, id)
    rescue StandardError => e
      e.message
    ensure
      db.close
    end
  end

  def get_group_status_info(id)
    db = connect_to_db

    begin
      GroupService.instance.get_group_status_info(db, id)
    rescue StandardError => e
      e.message
    ensure
      db.close
    end
  end

end
