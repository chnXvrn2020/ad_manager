# frozen_string_literal: true

class CompanyController

  def get_company_list(text, current_page = 1, keyword = nil)
    type = radio_to_type(text)

    return if type.nil?

    db = connect_to_db
    begin
      CompanyService.instance.get_company_list(db, type, current_page, keyword)
    rescue StandardError => e
      e.message
    ensure
      db.close
    end
  end

  def add_one_company(company)
    db = connect_to_db

    begin
      CompanyService.instance.add_one_company(db, company)
    rescue StandardError => e
      e.message
    ensure
      db.close
    end
  end

  def get_company_group(id, keyword = nil)
    db = connect_to_db

    begin
      CompanyService.instance.get_company_group(db, id, keyword)
    rescue StandardError => e
      e.message
    ensure
      db.close
    end
  end

  def add_child_company(company)
    db = connect_to_db

    begin
      CompanyService.instance.add_child_company(db, company)
    rescue StandardError => e
      e.message
    ensure
      db.close
    end
  end

  def get_company_info(id)
    db = connect_to_db

    begin
      CompanyService.instance.get_company_info(db, id)
    rescue StandardError => e
      e.message
    ensure
      db.close
    end
  end

  def get_one_company(id)
    db = connect_to_db

    data = begin
      CompanyService.instance.get_one_company(db, id)
    rescue StandardError => e
      e.message
    ensure
      db.close
    end

    Company.new(data[0])
  end

  def modify_one_company(company)
    db = connect_to_db

    begin
      CompanyService.instance.modify_one_company(db, company)
    rescue StandardError => e
      e.message
    ensure
      db.close
    end
  end

  def change_current_yn(id)
    db = connect_to_db

    begin
      db.transaction
      CompanyService.instance.change_current_yn(db, id)
      db.commit
    rescue StandardError => e
      db.rollback
      return e.message
    ensure
      db.close
    end

    true
  end

  def remove_one_company(id)
    db = connect_to_db

    begin
      CompanyService.instance.remove_one_company(db, id)
    rescue StandardError => e
      return e.message
    ensure
      db.close
    end

    true
  end

  def remove_company_group(id)
    db = connect_to_db

    begin
      CompanyService.instance.remove_company_group(db, id)
    rescue StandardError => e
      return e.message
    ensure
      db.close
    end

    true
  end

  def get_all_company_list(type, ides = nil, keyword = nil)
    db = connect_to_db

    begin
      CompanyService.instance.get_all_company_list(db, type, ides, keyword)
    rescue StandardError => e
      e.message
    ensure
      db.close
    end
  end

end
