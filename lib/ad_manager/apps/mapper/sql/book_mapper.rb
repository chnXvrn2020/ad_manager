# frozen_string_literal: true

require 'singleton'

class BookMapper
  include Singleton

  def select_book_list(db, type, group_id, keyword = nil)

    sql = <<~SQL
      SELECT tb.id, tb.name, ifnull(tc.name, '未鑑賞') AS status
      FROM tb_book tb
         LEFT JOIN tb_map g ON g.refer_tb = 'tb_book' AND g.refer_id = tb.id
         LEFT JOIN tb_book_status tbs ON tb.id = tbs.book_id
         LEFT JOIN tb_common tc ON tc.id = tbs.status
      WHERE tb.use_yn = 'Y'
        AND tb.type = ?
        AND g.from_id = ?
    SQL

    args = [type, group_id]

    unless keyword.nil?
      sql += 'AND tb.name LIKE ? '
      args << "%#{keyword}%"
    end

    sql += ' ORDER BY tb.created_date'

    db.execute(sql, args)

  end

  def select_book_count_by_group_id(db, type, group_id)

    sql = <<~SQL
      SELECT count(*)
      FROM tb_book tb
               LEFT JOIN tb_map g ON g.refer_tb = 'tb_book' AND g.refer_id = tb.id
      WHERE tb.use_yn = 'Y'
        AND tb.type = ?
        AND g.from_id = ?
        ORDER BY tb.created_date
    SQL

    args = [type, group_id]

    db.execute(sql, args).first[0]

  end

  def select_unselected_book_list(db, type, group_id, keyword = nil)
    sql = <<~SQL
      SELECT tb.id, tb.name
      FROM tb_book tb
               LEFT JOIN tb_map g ON g.refer_tb = 'tb_book' AND g.refer_id = tb.id
      WHERE tb.use_yn = 'Y'
        AND tb.type = ?
        AND g.from_id != ?
        AND g.refer_id NOT IN (SELECT m.refer_id
                                     FROM tb_map m
                                     WHERE m.refer_tb = 'tb_book'
                                       AND m.from_id = ?)
    SQL

    args = [type, group_id, group_id]

    unless keyword.nil?
      sql += 'AND tb.name LIKE ? '
      args << "%#{keyword}%"
    end

    sql += ' ORDER BY tb.created_date'

    db.execute(sql, args)
  end

  def select_book_by_id(db, id)

    sql = <<~SQL
      SELECT *
      FROM tb_book
      WHERE id =?
    SQL

    db.execute(sql, id)

  end

  def select_all(db, type, page, keyword = nil, status = nil)
    numeric_sort(db)

    sql = <<~SQL
      SELECT tb.id, tb.name
      FROM tb_book tb
               LEFT JOIN tb_book_status AS tbs ON tb.id = tbs.book_id
      WHERE tb.use_yn = 'Y'
        AND type = ?
    SQL

    args = [type]

    unless keyword.nil?
      sql += ' AND name LIKE ?'
      args << "%#{keyword}%"
    end

    case status
    when 32
      sql += ' GROUP BY tb.id, tb.name
               HAVING COUNT(tb.id) > 0 AND COUNT(tb.id) <= (SELECT COUNT(tbs.id))
               ORDER BY tbs.completion_date'
    when 3
      sql += ' GROUP BY tb.id, tb.name
               HAVING COUNT(tb.id) > (SELECT COUNT(tbs.id))
               ORDER BY numeric_sort(tb.name)'
    else
      sql += ' ORDER BY numeric_sort(name)'
    end

    sql += ' LIMIT ? OFFSET ?'

    args.concat([page.limit, page.offset])

    db.execute(sql, args)

  end

  def select_all_count(db, type, keyword = nil, status = nil)
    sql = <<~SQL
      SELECT COUNT(*)
      FROM (
      SELECT tb.id, tb.name
      FROM tb_book tb
               LEFT JOIN tb_book_status AS tbs ON tb.id = tbs.book_id
      WHERE tb.use_yn = 'Y'
        AND type = ?
    SQL

    args = [type]

    unless keyword.nil?
      sql += ' AND name LIKE?'
      args << "%#{keyword}%"
    end

    unless status == 1
      case status
      when 32
        sql += ' GROUP BY tb.id, tb.name
                 HAVING COUNT(tb.id) > 0 AND COUNT(tb.id) <= (SELECT COUNT(tbs.id))'
      when 3
        sql += ' GROUP BY tb.id, tb.name
                 HAVING COUNT(tb.id) > (SELECT COUNT(tbs.id))'
      end
    end

    sql += ') AS a'

    count = db.execute(sql, args)

    count[0][0]
  end

  def select_book_status(db, id)
    sql = <<~SQL
      SELECT  tbs.completion_date, tc.name AS status
      FROM tb_book_status tbs
      LEFT JOIN tb_common tc ON tc.id = tbs.status
      WHERE book_id = ?
    SQL

    db.execute(sql, id)
  end

  def select_completed_book_count_by_group_id(db, type, group_id)

    sql = <<~SQL
      SELECT COUNT(*)
      FROM tb_book tb
               LEFT JOIN tb_map g ON g.refer_tb = 'tb_book' AND g.refer_id = tb.id
               JOIN tb_book_status tbs ON tbs.book_id = tb.id
      WHERE tb.use_yn = 'Y'
        AND tb.type = ?
        AND g.from_id = ?
    SQL

    args = [type, group_id]

    db.execute(sql, args).first[0]

  end

  def insert_book(db, book)
    date = current_datetime

    sql = <<~SQL
      INSERT INTO tb_book
      (type,
       name,
       publisher,
       created_date,
       insert_date
       ) VALUES
       (?,?,?,?,?)
    SQL

    args = []
    args << book.type
    args << book.name
    args << book.publisher.join(',')
    args << book.created_date
    args << date

    db.execute(sql, args)
    db.last_insert_row_id

  end

  def update_book(db, book)
    date = current_datetime

    sql = <<~SQL

      UPDATE tb_book
      SET name = ?,
          publisher = ?,
          created_date = ?,
          update_date =?
      WHERE id =?
    SQL

    args = []
    args << book.name
    args << book.publisher.join(',')
    args << book.created_date
    args << date
    args << book.id

    db.execute(sql, args)

  end

  def delete_book(db, id)
    date = current_datetime

    sql = <<~SQL
      UPDATE tb_book
      SET use_yn = 'N',
          update_date =?
      WHERE id =?
    SQL

    args = []
    args << date
    args << id

    db.execute(sql, args)

  end

  def insert_book_complete(db, book_id, completion_date = nil)
    date = current_datetime
    completion_date = current_date if completion_date.nil?

    sql = <<~SQL
      INSERT INTO tb_book_status
      (
       book_id,
       completion_date,
       status,
       insert_date
       ) VALUES
       (?,?,?,?)
    SQL

    args = [book_id, completion_date, 32, date]

    db.execute(sql, args)

  end

  def check_duplicate_name(db, book)
    sql = <<~SQL
      SELECT id
      FROM tb_book
      WHERE type = ?
      AND name = ?
      AND publisher = ?
      AND created_date = ?
      AND use_yn = 'Y'
    SQL

    args = []
    args << book.type
    args << book.name
    args << book.publisher.join(',')
    args << book.created_date

    col = db.execute(sql, args)

    !col.empty?

  end

  def book_recommend_by_type_id(db, type_id)
    sql = <<~SQL
      SELECT DISTINCT tg.id, tg.name
      FROM tb_group tg
      LEFT JOIN tb_map tm ON tm.from_tb = 'tb_group' AND tm.refer_tb = 'tb_anime' AND tg.id = tm.from_id
      LEFT JOIN tb_anime ta ON tm.refer_id = ta.id
      LEFT JOIN tb_anime_status tas ON ta.id = tas.anime_id
      WHERE tas.status = 32
      AND tg.original = ?
    SQL

    args = [type_id]

    db.execute(sql, args)
  end

  def select_book_status_count_by_group_id(db, group_id)
    sql = <<~SQL
      SELECT COUNT(*)
      FROM tb_book tb
      LEFT JOIN tb_map tm ON tm.from_tb = 'tb_group' AND tm.refer_id = tb.id AND tm.refer_tb = 'tb_book'
      LEFT JOIN tb_group tg ON tg.id = tm.from_id
      LEFT JOIN tb_book_status tbs ON tb.id = tbs.book_id
      WHERE tg.id = ?
      AND tbs.status IS NOT NULL
    SQL

    args = [group_id]

    count = db.execute(sql, args)

    count[0][0]
  end

  def select_all_book_count_by_group_id(db, group_id)

    sql = <<~SQL
      SELECT count(*)
      FROM tb_book tb
               LEFT JOIN tb_map g ON g.refer_tb = 'tb_book' AND g.refer_id = tb.id
      WHERE tb.use_yn = 'Y'
        AND g.from_id = ?
        ORDER BY tb.created_date
    SQL

    args = [group_id]

    db.execute(sql, args).first[0]

  end
end

BookMapper.instance

