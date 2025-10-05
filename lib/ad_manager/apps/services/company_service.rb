# frozen_string_literal: true

require 'singleton'

class CompanyService
  include Singleton

  def get_company_list(db, type, current_page, keyword)
    count = CompanyMapper.instance.select_count_by_type(db, type, keyword)
    page = Page.new(count, current_page)
    company = CompanyMapper.instance.select_by_type(db, type, page, keyword)

    model = []

    company.each do |hash|
      model << Company.new(hash)
    end

    { 'model' => model, 'page' => page }
  end

  def add_one_company(db, company)
    if CompanyMapper.instance.check_duplicate_name(db, company)
      return false
    end

    CompanyMapper.instance.insert_company(db, company)
    true
  end

  def get_company_group(db, id, keyword)
    parent_id = CompanyMapper.instance.select_parent_id_by_id(db, id)
    id = parent_id.zero? ? id : parent_id

    data = CompanyMapper.instance.select_group_by_id(db, id, keyword)

    company = []

    data.each do |hash|
      company << Company.new(hash)
    end

    company
  end

  def get_company_info(db, id)
    company = CompanyMapper.instance.select_by_id(db, id)
    parent_id = CompanyMapper.instance.select_parent_id_by_id(db, id)
    id = parent_id.zero? ? id : parent_id

    count = CompanyMapper.instance.select_group_count_by_id(db, id)

    { 'company' => Company.new(company[0]), 'count' => count }
  end

  def add_child_company(db, company)
    if CompanyMapper.instance.check_duplicate_name(db, company)
      return false
    end
    parent_id = CompanyMapper.instance.select_parent_id_by_id(db, company.parent_id)
    company.parent_id = parent_id.zero? ? company.parent_id : parent_id

    CompanyMapper.instance.insert_child_company(db, company)

    true
  end

  def get_one_company(db, id)
    CompanyMapper.instance.select_by_id(db, id)
  end

  def modify_one_company(db, company)
    if CompanyMapper.instance.check_duplicate_name(db, company)
      return false
    end

    CompanyMapper.instance.update_by_id(db, company)
    true
  end

  def change_current_yn(db, id)
    parent_id = CompanyMapper.instance.select_parent_id_by_id(db, id)
    parent_id = parent_id.zero? ? id : parent_id

    CompanyMapper.instance.update_all_current_yn_by_id(db, parent_id)

    CompanyMapper.instance.update_current_yn_by_id(db, id)
  end

  def remove_one_company(db, id)
    CompanyMapper.instance.delete_by_id(db, id)
  end

  def remove_company_group(db, id)
    CompanyMapper.instance.delete_all_by_id(db, id)
  end

  def get_all_company_list(db, type, ides, keyword)
    data = CompanyMapper.instance.select_all_by_type(db, type, ides, keyword)

    company = []

    data.each do |hash|
      company << Company.new(hash)
    end

    company
  end

end

CompanyService.instance
