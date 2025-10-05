# frozen_string_literal: true

require 'singleton'

class ContentMapper
  include Singleton

  def select_content(db, page, keyword = nil, status = nil)
    sql = <<~SQL
      SELECT DISTINCT tc.id, tc.name
      FROM tb_content tc
      LEFT JOIN tb_map AS gr ON gr.from_tb = 'tb_content' AND gr.from_id = tc.id
      LEFT JOIN tb_group AS tg ON gr.refer_tb = 'tb_group' AND gr.refer_id = tg.id
      LEFT JOIN tb_map AS cl ON cl.from_tb = 'tb_group' AND gr.refer_id = cl.from_id
      LEFT JOIN tb_anime AS ta ON cl.refer_tb = 'tb_anime' AND cl.refer_id = ta.id
      LEFT JOIN tb_book AS tb ON cl.refer_tb = 'tb_book' AND cl.refer_id = tb.id
      LEFT JOIN tb_anime_status AS tas ON ta.id = tas.anime_id
      LEFT JOIN tb_book_status AS tbs ON tb.id = tbs.book_id
      WHERE tc.use_yn = 'Y'
    SQL

    args = []

    unless keyword.nil?
      sql += ' AND (tc.name LIKE ? OR ta.name LIKE ? OR tb.name LIKE ?)'
      3.times do
        args << "%#{keyword}%"
      end
    end


    unless status == 1
      case status
      when 32
        sql += ' GROUP BY tc.id, tc.name
                 HAVING COUNT(ta.id) > 0
                 AND COUNT(ta.id) <= COUNT(IIF(tas.status = 32, 1, NULL))
                 AND (COUNT(tb.id) = 0
                 OR COUNT(tb.id) <= COUNT(IIF(tbs.status = 32, 1, NULL)))'
      when 2
        sql += ' GROUP BY tc.id, tc.name
                 HAVING (COUNT(ta.id) > 0
                 AND (SELECT COUNT(tas.id)) > 0
                 AND ((SELECT COUNT(IIF(tas.status = 2, 1, NULL)) > 0)
                 OR COUNT(ta.id) > (SELECT COUNT(tas.id)))
                 AND COUNT(ta.id) >= (SELECT COUNT(tas.id)))
                 OR (COUNT(tb.id) > 0
                 AND (SELECT COUNT(tbs.id)) > 0
                 AND COUNT(tb.id) > (SELECT COUNT(tbs.id)))'
      when 3
        sql += 'GROUP BY tc.id, tc.name
                HAVING (COUNT(ta.id) > 0
                AND COUNT(ta.id) > (SELECT COUNT(tas.id)))
                OR (COUNT(tb.id) > 0
                AND (SELECT COUNT(tbs.id)) <= 0)'
      when 4
        sql += 'GROUP BY tc.id, tc.name
                HAVING (COUNT(ta.id) > 0
                AND (SELECT COUNT(tas.id)) > 0
                AND ((SELECT COUNT(IIF(tas.status = 4, 1, NULL)) > 0)))'
      end
    end

    sql += " ORDER BY tc.name
             LIMIT ? OFFSET ?"
    args.concat([page.limit, page.offset])

    db.execute(sql, args)

  end

  def select_content_count(db, keyword = nil, status = nil)
    sql = <<~SQL
      SELECT COUNT(*) AS count
      FROM (
         SELECT DISTINCT tc.id, tc.name
         FROM tb_content tc
                  LEFT JOIN tb_map AS gr ON gr.from_tb = 'tb_content' AND gr.from_id = tc.id
                  LEFT JOIN tb_group AS tg ON gr.refer_tb = 'tb_group' AND gr.refer_id = tg.id
                  LEFT JOIN tb_map AS cl ON cl.from_tb = 'tb_group' AND gr.refer_id = cl.from_id
                  LEFT JOIN tb_anime AS ta ON cl.refer_tb = 'tb_anime' AND cl.refer_id = ta.id
                  LEFT JOIN tb_book AS tb ON cl.refer_tb = 'tb_book' AND cl.refer_id = tb.id
                  LEFT JOIN tb_anime_status AS tas ON ta.id = tas.anime_id
                  LEFT JOIN tb_book_status AS tbs ON tb.id = tbs.book_id
         WHERE tc.use_yn = 'Y'
    SQL

    args = []

    unless keyword.nil?
      sql += ' AND tc.name LIKE ?'
      args << "%#{keyword}%"
    end

    unless status == 1
      case status
      when 32
        sql += ' GROUP BY tc.id, tc.name
                 HAVING (COUNT(ta.id) > 0 AND COUNT(ta.id) <= (SELECT COUNT(tas.id)))
                 OR (COUNT(tb.id) > 0 AND COUNT(tb.id) <= (SELECT COUNT(tbs.id)))'
      when 2
        sql += ' GROUP BY tc.id, tc.name
                 HAVING (COUNT(ta.id) > 0
                 AND (SELECT COUNT(tas.id)) > 0
                 AND ((SELECT COUNT(IIF(tas.status = 2, 1, NULL)) > 0)
                 OR COUNT(ta.id) > (SELECT COUNT(tas.id)))
                 AND COUNT(ta.id) >= (SELECT COUNT(tas.id)))
                 OR (COUNT(tb.id) > 0
                 AND (SELECT COUNT(tbs.id)) > 0
                 AND COUNT(tb.id) > (SELECT COUNT(tbs.id)))'
      when 3
        sql += 'GROUP BY tc.id, tc.name
                HAVING (COUNT(ta.id) > 0
                AND COUNT(ta.id) > (SELECT COUNT(tas.id)))
                OR (COUNT(tb.id) > 0
                AND (SELECT COUNT(tbs.id)) <= 0)'
      when 4
        sql += 'GROUP BY tc.id, tc.name
                HAVING (COUNT(ta.id) > 0
                AND (SELECT COUNT(tas.id)) > 0
                AND ((SELECT COUNT(IIF(tas.status = 4, 1, NULL)) > 0)))'
      end
    end

    sql += ') AS a'

    count = db.execute(sql, args)

    count[0]['count']

  end

  def select_by_id(db, id)

    sql = <<~SQL
      SELECT *
      FROM tb_content
      WHERE id = ?
    SQL

    db.execute(sql, id)

  end

  def insert_content(db, name)
    date = current_datetime
    sql = <<~SQL
      INSERT INTO
          tb_content
          (
           name,
           insert_date
           )
      VALUES
          (
           ?,
           ?
           )
    SQL

    args = [name, date]

    db.execute(sql, args)
    db.last_insert_row_id

  end

  def update_content(db, content)
    date = current_datetime
    sql = <<~SQL
      UPDATE
          tb_content
      SET
          name = ?,
          update_date = ?
      WHERE
          id = ?
    SQL

    args = [content.name, date, content.id]

    db.execute(sql, args)

  end

  def delete_content(db, id)
    date = current_datetime
    sql = <<~SQL
      UPDATE
          tb_content
      SET
          use_yn = 'N',
          delete_date = ?
      WHERE
          id = ?
    SQL

    args = [date, id]

    db.execute(sql, args)
  end

  def check_duplicate_name(db, name)
    sql = <<~SQL
      SELECT id
      FROM tb_content
      WHERE name = ?
      AND use_yn = 'Y'
    SQL

    col = db.execute(sql, name)

    !col.empty?

  end

  def select_all_content_with_group(db)
    sql = <<~SQL
      SELECT DISTINCT tc.id, tc.name
      FROM tb_content tc
      LEFT JOIN tb_map tm ON tm.from_tb = 'tb_content' AND tc.id = tm.from_id
      LEFT JOIN tb_group tg ON tm.refer_tb = 'tb_group' AND tg.id = tm.refer_id
      WHERE tc.use_yn = 'Y'
      AND tg.use_yn = 'Y'
    SQL

    db.execute(sql)

  end

end

ContentMapper.instance
