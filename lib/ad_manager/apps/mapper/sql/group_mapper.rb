# frozen_string_literal: true

require 'singleton'

class GroupMapper
  include Singleton

  def select_list(db, id = nil, param = nil)
    sql = <<~SQL
      SELECT tg.id, tg.original, o.name AS original_name, tg.name
      FROM tb_group tg
      LEFT JOIN tb_map c ON c.refer_tb = 'tb_group' AND c.refer_id = tg.id
      LEFT JOIN tb_common o ON tg.original = o.id
      WHERE tg.use_yn = 'Y'
    SQL

    args = []

    unless param.nil?
      sql += ' AND tg.name LIKE ?'
      args << "%#{param['keyword']}%"

      unless param['original'].zero?
        sql += ' AND tg.original = ?'
        args << param['original']
      end
    end

    if id.nil?
      sql += ' AND c.from_id IS NULL'
    else
      sql += " AND (c.from_id IS NULL OR c.from_id != ?)
               AND c.refer_id NOT IN (SELECT m.refer_id
                          FROM tb_map m
                          WHERE m.refer_tb = 'tb_group'
                            AND m.from_id = ?)"
      args.concat([id, id])
    end
    sql += ' ORDER BY tg.name'

    db.execute(sql, args)

  end

  def select_by_content_id(db, id, keyword = nil)
    sql = <<~SQL
      SELECT DISTINCT tg.*
      FROM tb_group tg
      LEFT JOIN tb_map AS ca ON ca.from_tb = 'tb_content' AND ca.refer_id = tg.id
      LEFT JOIN tb_map AS cl ON cl.from_tb = 'tb_group' AND tg.id = cl.from_id
      LEFT JOIN tb_anime AS ta ON cl.refer_tb = 'tb_anime' AND cl.refer_id = ta.id
      LEFT JOIN tb_book AS tb ON cl.refer_tb = 'tb_book' AND cl.refer_id = tb.id
      WHERE ca.from_id = ?
    SQL

    args = [id]

    unless keyword.nil?
      sql += ' AND tg.name LIKE ?'
      args << "%#{keyword}%"
    end

    sql += " ORDER BY ifnull(ta.created_date, ifnull(tb.created_date, '9999-12-31'))"

    db.execute(sql, args)

  end

  def select_selected_group_list(db, id)
    sql = <<~SQL
      SELECT DISTINCT tg.id, tg.original, o.name AS original_name, tg.name
      FROM tb_group tg
      LEFT JOIN tb_map AS ca ON ca.from_tb = 'tb_content' AND ca.refer_id = tg.id
      LEFT JOIN tb_map AS cl ON cl.from_tb = 'tb_group' AND tg.id = cl.from_id
      LEFT JOIN tb_anime AS ta ON cl.refer_tb = 'tb_anime' AND cl.refer_id = ta.id
      LEFT JOIN tb_book AS tb ON cl.refer_tb = 'tb_book' AND cl.refer_id = tb.id
      LEFT JOIN tb_common o ON tg.original = o.id
      WHERE tg.use_yn = 'Y'
      AND ca.from_tb = 'tb_content'
      AND ca.from_id = ?
      ORDER BY ifnull(ta.created_date, ifnull(tb.created_date, '9999-12-31'))
    SQL

    db.execute(sql, id)

  end

  def select_by_id(db, id)

    sql = <<~SQL
      SELECT tg.id, tg.original, tg.name, o.name AS original_name
      FROM tb_group tg
      LEFT JOIN tb_common o ON tg.original = o.id
      WHERE tg.id = ?
    SQL

    db.execute(sql, id)

  end

  def select_all(db, page, keyword = nil, status = nil)
    sql = <<~SQL
      SELECT DISTINCT tg.id, tg.name
      FROM tb_group tg
      LEFT JOIN tb_map AS cl ON cl.from_tb = 'tb_group' AND cl.from_id = tg.id
      LEFT JOIN tb_anime AS ta ON cl.refer_tb = 'tb_anime' AND cl.refer_id = ta.id
      LEFT JOIN tb_book AS tb ON cl.refer_tb = 'tb_book' AND cl.refer_id = tb.id
      LEFT JOIN tb_anime_status AS tas ON ta.id = tas.anime_id
      LEFT JOIN tb_book_status AS tbs ON tb.id = tbs.book_id
      WHERE tg.use_yn = 'Y'
    SQL

    args = []

    unless keyword.nil?
      sql += ' AND (tg.name LIKE ? OR ta.name LIKE ? OR tb.name LIKE ?) '
      3.times do
        args << "%#{keyword}%"
      end
    end

    unless status == 1
      case status
      when 32
        sql += ' GROUP BY tg.id, tg.name
                 HAVING (COUNT(ta.id) > 0
                 AND COUNT(ta.id) <= (SELECT COUNT(tas.id)))
                 OR (COUNT(tb.id) > 0
                 AND COUNT(tb.id) <= (SELECT COUNT(tbs.id)))'
      when 2
        sql += ' GROUP BY tg.id, tg.name
                 HAVING (COUNT(ta.id) > 0
                 AND (SELECT COUNT(tas.id)) > 0
                 AND ((SELECT COUNT(IIF(tas.status = 2, 1, NULL)) > 0)
                 OR COUNT(ta.id) > (SELECT COUNT(tas.id)))
                 AND COUNT(ta.id) >= (SELECT COUNT(tas.id)))
                 OR (COUNT(tb.id) > 0
                 AND (SELECT COUNT(tbs.id)) > 0
                 AND COUNT(tb.id) > (SELECT COUNT(tbs.id)))'
      when 3
        sql += 'GROUP BY tg.id, tg.name
                HAVING (COUNT(ta.id) > 0
                AND COUNT(ta.id) > (SELECT COUNT(tas.id)))
                OR (COUNT(tb.id) > 0
                AND (SELECT COUNT(tbs.id)) <= 0)'
      when 4
        sql += 'GROUP BY tg.id, tg.name
                HAVING (COUNT(ta.id) > 0
                AND (SELECT COUNT(tas.id)) > 0
                AND ((SELECT COUNT(IIF(tas.status = 4, 1, NULL)) > 0)))'
      end
    end

    sql += ' ORDER BY tg.name
             LIMIT ? OFFSET ?'

    args.concat([page.limit, page.offset])

    db.execute(sql, args)

  end

  def select_all_count(db, keyword = nil, status = nil)
    sql = <<~SQL
      SELECT COUNT(*) AS count
      FROM (
      SELECT DISTINCT tg.id, tg.name
      FROM tb_group tg
      LEFT JOIN tb_map AS cl ON cl.from_tb = 'tb_group' AND cl.from_id = tg.id
      LEFT JOIN tb_anime AS ta ON cl.refer_tb = 'tb_anime' AND cl.refer_id = ta.id
      LEFT JOIN tb_book AS tb ON cl.refer_tb = 'tb_book' AND cl.refer_id = tb.id
      LEFT JOIN tb_anime_status AS tas ON ta.id = tas.anime_id
      LEFT JOIN tb_book_status AS tbs ON tb.id = tbs.book_id
      WHERE tg.use_yn = 'Y'
    SQL

    args = []

    unless keyword.nil?
      sql += ' AND (tg.name LIKE ? OR ta.name LIKE ? OR tb.name LIKE ?) '
      3.times do
        args << "%#{keyword}%"
      end
    end

    unless status == 1
      case status
      when 32
        sql += ' GROUP BY tg.id, tg.name
                 HAVING (COUNT(ta.id) > 0
                 AND COUNT(ta.id) <= (SELECT COUNT(tas.id)))
                 OR (COUNT(tb.id) > 0
                 AND COUNT(tb.id) <= (SELECT COUNT(tbs.id)))'
      when 2
        sql += ' GROUP BY tg.id, tg.name
                 HAVING (COUNT(ta.id) > 0
                 AND (SELECT COUNT(tas.id)) > 0
                 AND ((SELECT COUNT(IIF(tas.status = 2, 1, NULL)) > 0)
                 OR COUNT(ta.id) > (SELECT COUNT(tas.id)))
                 AND COUNT(ta.id) >= (SELECT COUNT(tas.id)))
                 OR (COUNT(tb.id) > 0
                 AND (SELECT COUNT(tbs.id)) > 0
                 AND COUNT(tb.id) > (SELECT COUNT(tbs.id)))'
      when 3
        sql += 'GROUP BY tg.id, tg.name
                HAVING (COUNT(ta.id) > 0
                AND COUNT(ta.id) > (SELECT COUNT(tas.id)))
                OR (COUNT(tb.id) > 0
                AND (SELECT COUNT(tbs.id)) <= 0)'
      when 4
        sql += 'GROUP BY tg.id, tg.name
                HAVING (COUNT(ta.id) > 0
                AND (SELECT COUNT(tas.id)) > 0
                AND ((SELECT COUNT(IIF(tas.status = 4, 1, NULL)) > 0)))'
      end
    end

    sql += ') AS a'

    db.execute(sql, args)

    count = db.execute(sql, args)

    count[0]['count']
  end

  def select_book_group_list(db, type, page, keyword, status)
    numeric_sort(db)

    sql = <<~SQL
      SELECT DISTINCT tg.id, tg.name
      FROM tb_group tg
      LEFT JOIN tb_map AS cl ON cl.from_tb = 'tb_group' AND cl.from_id = tg.id
      JOIN tb_book AS tb ON cl.refer_tb = 'tb_book' AND cl.refer_id = tb.id
      LEFT JOIN tb_book_status AS tbs ON tb.id = tbs.book_id
      WHERE tg.use_yn = 'Y'
      AND tb.type = ?
    SQL

    args = [type]

    unless keyword.nil?
      sql += ' AND (tg.name LIKE ? OR tb.name LIKE ?) '
      2.times do
        args << "%#{keyword}%"
      end
    end

    unless status == 1
      case status
      when 32
        sql += ' GROUP BY tg.id, tg.name
                 HAVING COUNT(tb.id) > 0
                 AND COUNT(tb.id) <= (SELECT COUNT(tbs.id))
                 ORDER BY tbs.completion_date'
      when 2
        sql += ' GROUP BY tg.id, tg.name
                 HAVING COUNT(tb.id) > 0
                 AND (SELECT COUNT(tbs.id)) > 0
                 AND COUNT(tb.id) > (SELECT COUNT(tbs.id))
                 ORDER BY numeric_sort(tb.name)'
      when 3
        sql += ' GROUP BY tg.id, tg.name
                 HAVING COUNT(tb.id) > 0 AND (SELECT COUNT(tbs.id)) <= 0
                 ORDER BY numeric_sort(tb.name)'
      end
    end

    sql += ' LIMIT ? OFFSET ?'

    args.concat([page.limit, page.offset])

    db.execute(sql, args)
  end

  def select_book_group_list_count(db, type, keyword, status)

    sql = <<~SQL
      SELECT COUNT(*) AS count
      FROM (
      SELECT DISTINCT tg.id, tg.name
      FROM tb_group tg
      LEFT JOIN tb_map AS cl ON cl.from_tb = 'tb_group' AND cl.from_id = tg.id
      JOIN tb_book AS tb ON cl.refer_tb = 'tb_book' AND cl.refer_id = tb.id
      LEFT JOIN tb_book_status AS tbs ON tb.id = tbs.book_id
      WHERE tg.use_yn = 'Y'
      AND tb.type = ?
    SQL

    args = [type]

    unless keyword.nil?
      sql += ' AND (tg.name LIKE ? OR tb.name LIKE ?) '
      2.times do
        args << "%#{keyword}%"
      end
    end

    unless status == 1
      case status
      when 32
        sql += ' GROUP BY tg.id, tg.name
                 HAVING COUNT(tb.id) > 0
                 AND COUNT(tb.id) <= (SELECT COUNT(tbs.id))'
      when 2
        sql += ' GROUP BY tg.id, tg.name
                 HAVING COUNT(tb.id) > 0
                 AND (SELECT COUNT(tbs.id)) > 0
                 AND COUNT(tb.id) > (SELECT COUNT(tbs.id))'
      when 3
        sql += ' GROUP BY tg.id, tg.name
                 HAVING COUNT(tb.id) > 0 AND (SELECT COUNT(tbs.id)) <= 0'
      end
    end

    sql += ') AS a'

    count = db.execute(sql, args)

    count[0]['count']
  end

  def insert_group(db, group)
    date = current_datetime
    sql = <<~SQL
      INSERT INTO
          tb_group
          (
           original,
           name,
           insert_date
           )
      VALUES
          (
           ?,
           ?,
           ?
           )
    SQL

    args = [group.original, group.name, date]

    db.execute(sql, args)

  end

  def update_group(db, group)
    date = current_datetime
    sql = <<~SQL
      UPDATE
          tb_group
      SET
          original = ?,
          name = ?,
          update_date = ?
      WHERE
          id = ?
    SQL

    args = [group.original, group.name, date, group.id]

    db.execute(sql, args)

  end

  def delete_group(db, id)
    date = current_datetime

    sql = <<~SQL
      UPDATE
          tb_group
      SET
          use_yn = 'N',
          delete_date = ?
      WHERE
          id = ?
    SQL

    args = [date, id]

    db.execute(sql, args)

  end

  def check_duplicate_name(db, group)
    sql = <<~SQL
      SELECT id
      FROM tb_group
      WHERE name = ?
      AND original = ?
      AND use_yn = 'Y'
    SQL

    args = [group.name, group.original]

    col = db.execute(sql, args)

    !col.empty?

  end

  def select_group_list_by_content_id(db, content_id)
    sql = <<~SQL
      SELECT tg.id, tg.name
      FROM tb_group tg
      LEFT JOIN tb_map tm ON tm.from_tb = 'tb_content' AND tg.id = tm.refer_id
      WHERE use_yn = 'Y'
      AND tm.from_id = ?
    SQL

    args = [content_id]

    db.execute(sql, args)

  end

  def select_anime_status_list_by_group_id(db, group_id)
    sql = <<~SQL
      SELECT tas.status
      FROM tb_group tg
               LEFT JOIN tb_map AS ca ON ca.from_tb = 'tb_content' AND ca.refer_id = tg.id
               LEFT JOIN tb_map AS cl ON cl.from_tb = 'tb_group' AND tg.id = cl.from_id
               LEFT JOIN tb_anime AS ta ON cl.refer_tb = 'tb_anime' AND cl.refer_id = ta.id
               LEFT JOIN tb_anime_status AS tas ON ta.id = tas.anime_id
      WHERE tg.id = ?
      AND cl.refer_tb = 'tb_anime'
    SQL

    args = [group_id]

    db.execute(sql, args)
  end

  def select_book_status_list_by_group_id(db, group_id)
    sql = <<~SQL
      SELECT tbs.status
      FROM tb_group tg
               LEFT JOIN tb_map AS ca ON ca.from_tb = 'tb_content' AND ca.refer_id = tg.id
               LEFT JOIN tb_map AS cl ON cl.from_tb = 'tb_group' AND tg.id = cl.from_id
               LEFT JOIN tb_book AS tb ON cl.refer_tb = 'tb_book' AND cl.refer_id = tb.id
               LEFT JOIN tb_book_status AS tbs ON tb.id = tbs.book_id
      WHERE tg.id = ?
        AND cl.refer_tb = 'tb_book'
    SQL

    args = [group_id]

    db.execute(sql, args)
  end

end

GroupMapper.instance
