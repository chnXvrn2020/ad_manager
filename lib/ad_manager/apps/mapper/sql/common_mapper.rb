# frozen_string_literal: true
#
require 'singleton'

class CommonMapper
  include Singleton

  def select_by_type(db, type, page = nil, keyword = nil)

    sql = <<~SQL
      SELECT *
      FROM tb_common
      WHERE type = ?
      AND use_yn = 'Y'
    SQL

    args = [type]

    unless keyword.nil?
      sql += ' AND name LIKE ?'
      args << "%#{keyword}%"
    end

    unless page.nil?
      sql += " ORDER BY insert_date
               LIMIT ? OFFSET ?"
      args.concat([page.limit, page.offset])
    end

    db.execute(sql, args)

  end

  def select_count_by_type(db, type, keyword = nil)

    sql = <<~SQL
      SELECT COUNT(*)
      FROM tb_common
      WHERE type = ?
      AND use_yn = 'Y'
    SQL

    args = [type]

    unless keyword.nil?
      sql += ' AND name LIKE ?'
      args << "%#{keyword}%"
    end

    count = db.execute(sql, args)

    count[0][0]

  end

  def select_by_types(db, types)

    placeholder = types.map { '?' }.join(',')

    sql = <<-SQL
      SELECT *
      FROM tb_common
      WHERE type IN (#{placeholder})
      AND use_yn = 'Y'
    SQL

    db.execute(sql, types)
  end

  def select_by_id(db, id)

    sql = <<~SQL
      SELECT *
      FROM tb_common
      WHERE id = ?
    SQL

    db.execute(sql, id)

  end

  def insert_common(db, common)
    date = current_datetime
    args = [common.type, common.name, date]

    sql = <<~SQL
      INSERT INTO tb_common (
        type,
        name,
        insert_date
      ) VALUES (
        ?,
        ?,
        ?
      )
    SQL

    db.execute(sql, args)

  end

  def update_by_id(db, common)
    date = current_datetime
    args = [common.name, date, common.id]

    sql = <<~SQL
      UPDATE tb_common
      SET name = ?,
          update_date = ?
      WHERE id = ?
    SQL

    db.execute(sql, args)

  end

  def delete_by_id(db, id)
    date = current_datetime
    args = [date, id]

    sql = <<~SQL
      UPDATE tb_common
      SET use_yn = 'N',
          delete_date = ?
      WHERE id = ?
    SQL

    db.execute(sql, args)
  end

  def check_duplicate_name(db, common)
    args = [common.name, common.type]
    sql = <<~SQL
      SELECT id
      FROM tb_common
      WHERE name = ?
      AND type = ?
      AND use_yn = 'Y'
    SQL

    col = db.execute(sql, args)

    !col.empty?
  end
end

CommonMapper.instance
