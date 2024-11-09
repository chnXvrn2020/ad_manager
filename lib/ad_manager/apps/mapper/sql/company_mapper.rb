# frozen_string_literal: true

require 'singleton'

class CompanyMapper
  include Singleton

  def select_by_type(db, type, page, keyword = nil)
    sql = <<~SQL
      SELECT *
      FROM tb_company
      WHERE type = ?
      AND current_yn = 'Y'
      AND use_yn = 'Y'
    SQL

    args = [type]

    unless keyword.nil?
      sql += " AND (
                    name LIKE ?
                    OR
                    parent_id = (SELECT a.id FROM tb_company a WHERE name LIKE ?)
                    OR
                    id = (SELECT b.parent_id FROM tb_company b WHERE name LIKE ?)
                    ) "

      args.concat(%W[%#{keyword}% %#{keyword}% %#{keyword}%])
    end

    sql += " ORDER BY name
             LIMIT ? OFFSET ?"
    args.concat([page.limit, page.offset])

    db.execute(sql, args)

  end

  def select_count_by_type(db, type, keyword = nil)
    sql = <<~SQL
      SELECT COUNT(*)
      FROM tb_company
      WHERE type = ?
      AND current_yn = 'Y'
      AND use_yn = 'Y'
    SQL

    args = [type]

    unless keyword.nil?
      sql += " AND (
                    name LIKE ?
                    OR
                    parent_id = (SELECT a.id FROM tb_company a WHERE name LIKE ?)
                    OR
                    id = (SELECT b.parent_id FROM tb_company b WHERE name LIKE ?)
                    ) "

      args.concat(%W[%#{keyword}% %#{keyword}% %#{keyword}%])
    end

    count = db.execute(sql, args)

    count[0][0]

  end

  def select_all_by_type(db, type, ides, keyword = nil)
    sql = <<~SQL
      SELECT *
      FROM tb_company
      WHERE type = ?
      AND use_yn = 'Y'
    SQL

    args = [type]

    unless ides.empty?
      placeholder = ides.map { '?' }.join(',')
      id_array = []

      sql += " AND id NOT IN (#{placeholder})
               AND parent_id NOT IN (#{placeholder})
               AND id NOT IN (SELECT a.parent_id
                 FROM tb_company a
                 WHERE a.id IN (#{placeholder}))
               AND id NOT IN (SELECT a.id
                 FROM tb_company a
                 WHERE a.parent_id != 0
                   AND a.parent_id IN (SELECT b.parent_id
                              FROM tb_company b
                              WHERE b.id IN (#{placeholder})))"
      ides.each do |id|
        id_array << id
      end

      args.concat(id_array, id_array, id_array, id_array)
    end

    unless keyword.nil?
      sql += ' AND name LIKE ?'
      args << "%#{keyword}%"
    end

    sql += ' ORDER BY name'

    db.execute(sql, args)
  end

  def select_selected_group_list_by_type(db, type, ides)
    sql = <<~SQL
      SELECT *
      FROM tb_company
      WHERE type = ?
      AND use_yn = 'Y'
    SQL

    placeholder = ides.map { '?' }.join(',')
    sql += " AND id IN (#{placeholder})"

    p sql
    p ides

    args = [type, ides]

    db.execute(sql, args)

  end

  def select_by_id(db, id)
    sql = <<~SQL
      SELECT *
      FROM tb_company
      WHERE id = ?
    SQL

    db.execute(sql, id)

  end

  def select_group_by_id(db, id, keyword = nil)

    sql = <<~SQL
      SELECT *
      FROM tb_company
      WHERE (id = ? OR parent_id = ?)
      AND use_yn = 'Y'
    SQL

    args = [id, id]

    unless keyword.nil?
      sql += ' AND name LIKE ?'
      args << "%#{keyword}%"
    end

    db.execute(sql, args)
  end

  def select_parent_id_by_id(db, id)
    sql = <<~SQL
      SELECT parent_id
      FROM tb_company
      WHERE id = ?
    SQL

    parent_id = db.execute(sql, id)

    parent_id[0][0]

  end

  def select_group_count_by_id(db, id)
    sql = <<~SQL
      SELECT COUNT(*)
      FROM tb_company
      WHERE (id = ? OR parent_id = ?)
      AND use_yn = 'Y'
    SQL

    args = [id, id]

    count = db.execute(sql, args)

    count[0][0]
  end

  def insert_company(db, company)
    date = current_datetime
    sql = <<~SQL
      INSERT INTO tb_company (
        type,
        name,
        insert_date
      ) VALUES (
        ?,
        ?,
        ?
      )
    SQL

    args = [company.type, company.name, date]

    db.execute(sql, args)

  end

  def insert_child_company(db, company)
    date = current_datetime
    sql = <<~SQL
      INSERT INTO tb_company (
        type,
        name,
        parent_id,
        current_yn,
        insert_date
      ) VALUES (
        ?,
        ?,
        ?,
        'N',
        ?
      )
    SQL

    args = [company.type, company.name, company.parent_id, date]

    db.execute(sql, args)

  end

  def update_by_id(db, company)
    date = current_datetime
    sql = <<~SQL
      UPDATE tb_company
      SET
        name = ?,
        update_date = ?
      WHERE id = ?
    SQL

    args = [company.name, date, company.id]

    db.execute(sql, args)

  end

  def update_all_current_yn_by_id(db, id)
    sql = <<~SQL
      UPDATE tb_company
      SET
        current_yn = 'N'
      WHERE (id = ? OR parent_id = ?)
    SQL

    args = [id, id]

    db.execute(sql, args)

  end

  def update_current_yn_by_id(db, id)
    date = current_datetime
    sql = <<~SQL
      UPDATE tb_company
      SET
        current_yn = 'Y',
        update_date = ?
      WHERE id = ?
    SQL

    args = [date, id]

    db.execute(sql, args)

  end

  def delete_by_id(db, id)
    date = current_datetime
    sql = <<~SQL
      UPDATE tb_company
      SET
        use_yn = 'N',
        delete_date = ?
      WHERE id = ?
    SQL

    args = [date, id]

    db.execute(sql, args)

  end

  def delete_all_by_id(db, id)
    date = current_datetime

    sql = <<~SQL
      UPDATE tb_company
      SET
        use_yn = 'N',
        delete_date = ?
      WHERE (id = ? OR parent_id = ?)
    SQL

    args = [date, id, id]

    db.execute(sql, args)

  end

  def check_duplicate_name(db, company)
    sql = <<~SQL
      SELECT id
      FROM tb_company
      WHERE type = ?
      AND name = ?
      AND use_yn = 'Y'
    SQL

    args = [company.type, company.name]

    col = db.execute(sql, args)

    !col.empty?
  end

end

CompanyMapper.instance
