# frozen_string_literal: true

class CompanyController

  def get_company_list(text, current_page = 1, keyword = nil)
    type = radio_to_type(text)

    return if type.nil?

    db = connect_to_db
    count = CompanyMapper.instance.select_count_by_type(db, type, keyword)
    page = Page.new(count, current_page)
    company = CompanyMapper.instance.select_by_type(db, type, page, keyword)
    db.close

    model = []

    company.each do |hash|
      model << Company.new(hash)
    end

    { 'model' => model, 'page' => page }
  end

  def add_one_company(company)
    db = connect_to_db

    if CompanyMapper.instance.check_duplicate_name(db, company)
      db.close
      return false
    end

    CompanyMapper.instance.insert_company(db, company)
    db.close

    true
  end

  def get_company_group(id, keyword = nil)
    db = connect_to_db
    parent_id = CompanyMapper.instance.select_parent_id_by_id(db, id)
    id = parent_id.zero? ? id : parent_id

    data = CompanyMapper.instance.select_group_by_id(db, id, keyword)
    db.close

    company = []

    data.each do |hash|
      company << Company.new(hash)
    end

    company
  end

  def get_company_group_count(id)
    db = connect_to_db

    parent_id = CompanyMapper.instance.select_parent_id_by_id(db, id)
    id = parent_id.zero? ? id : parent_id

    count = CompanyMapper.instance.select_group_count_by_id(db, id)
    db.close

    count
  end

  def add_child_company(company)
    db = connect_to_db

    if CompanyMapper.instance.check_duplicate_name(db, company)
      db.close
      return false
    end
    parent_id = CompanyMapper.instance.select_parent_id_by_id(db, company.parent_id)
    company.parent_id = parent_id.zero? ? company.parent_id : parent_id

    CompanyMapper.instance.insert_child_company(db, company)
    db.close

    true
  end

  def get_one_company(id)
    db = connect_to_db
    data = CompanyMapper.instance.select_by_id(db, id)
    db.close

    Company.new(data[0])
  end

  def modify_one_company(company)
    db = connect_to_db

    if CompanyMapper.instance.check_duplicate_name(db, company)
      db.close
      return false
    end

    CompanyMapper.instance.update_by_id(db, company)
    db.close

    true
  end

  def change_current_yn(id)
    db = connect_to_db

    parent_id = CompanyMapper.instance.select_parent_id_by_id(db, id)
    parent_id = parent_id.zero? ? id : parent_id

    CompanyMapper.instance.update_all_current_yn_by_id(db, parent_id)

    CompanyMapper.instance.update_current_yn_by_id(db, id)
    db.close
  end

  def remove_one_company(id)
    db = connect_to_db
    CompanyMapper.instance.delete_by_id(db, id)
    db.close
  end

  def remove_company_group(id)
    db = connect_to_db
    CompanyMapper.instance.delete_all_by_id(db, id)
    db.close
  end

  def get_all_company_list(type, ides = nil, keyword = nil)
    db = connect_to_db
    data = CompanyMapper.instance.select_all_by_type(db, type, ides, keyword)
    db.close

    company = []

    data.each do |hash|
      company << Company.new(hash)
    end

    company

  end

  def get_selected_company_list(type, ides)
    db = connect_to_db
    data = CompanyMapper.instance.select_selected_group_list_by_type(db, type, ides)
    db.close

    company = []

    data.each do |hash|
      company << Company.new(hash)
    end

    company

  end

end
