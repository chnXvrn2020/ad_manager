# frozen_string_literal: true

require 'singleton'

class AnimeMapper
  include Singleton

  def select_anime_list_by_group_id(db, group_id, keyword = nil)

    sql = <<~SQL
      SELECT ta.id, ta.name, ifnull(tc.name, '未鑑賞') AS status
      FROM tb_anime ta
         LEFT JOIN tb_map g ON g.refer_tb = 'tb_anime' AND g.refer_id = ta.id
         LEFT JOIN tb_anime_status tas ON ta.id = tas.anime_id
         LEFT JOIN tb_common tc ON tc.id = tas.status
      WHERE ta.use_yn = 'Y'
        AND g.from_id = ?
    SQL

    args = [group_id]

    unless keyword.nil?
      sql += ' AND ta.name LIKE ?'
      args << "%#{keyword}%"
    end

    sql += ' ORDER BY ta.created_date'

    db.execute(sql, args)

  end

  def select_unselected_anime_list_by_group_id(db, group_id, keyword = nil)
    sql = <<~SQL
      SELECT ta.id, ta.name
      FROM tb_anime ta
               LEFT JOIN tb_map g ON g.refer_tb = 'tb_anime' AND g.refer_id = ta.id
      WHERE ta.use_yn = 'Y'
        AND g.from_id != ?
        AND g.refer_id NOT IN (SELECT m.refer_id
                               FROM tb_map m
                               WHERE m.refer_tb = 'tb_anime'
                                 AND m.from_id = ?)
    SQL

    args = [group_id, group_id]

    unless keyword.nil?
      sql += ' AND ta.name LIKE ?'
      args << "%#{keyword}%"
    end

    sql += ' ORDER BY ta.created_date'

    db.execute(sql, args)

  end

  def select_anime_by_id(db, id)

    sql = <<~SQL
      SELECT *
      FROM tb_anime
      WHERE id =?
    SQL

    db.execute(sql, id)

  end

  def select_all(db, page, keyword = nil, status = nil)
    numeric_sort(db)

    sql = <<~SQL
      SELECT ta.id, ta.name
      FROM tb_anime ta
      LEFT JOIN tb_anime_status AS tas ON ta.id = tas.anime_id
      WHERE ta.use_yn = 'Y'
    SQL

    args = []

    unless keyword.nil?
      sql += ' AND name LIKE ?'
      args << "%#{keyword}%"
    end

    case status
    when 32
      sql += 'GROUP BY ta.id, ta.name
              HAVING (COUNT(ta.id) > 0
              AND COUNT(ta.id) <= (SELECT COUNT(tas.id)))
              AND tas.status = ?
              ORDER BY tas.completion_date'

      args << status
    when 2, 4
      sql += ' AND tas.status = ?
               ORDER BY ta.name'

      args << status
    when 3
      sql += ' AND tas.anime_id IS NULL
               ORDER BY ta.name'
    else
      sql += ' ORDER BY ta.name'
    end

    sql += ' LIMIT ? OFFSET ?'

    args.concat([page.limit, page.offset])

    db.execute(sql, args)

  end

  def select_all_count(db, keyword = nil, status = nil)
    sql = <<~SQL
      SELECT COUNT(*) AS count
      FROM (
          SELECT ta.id, ta.name
          FROM tb_anime ta
          LEFT JOIN tb_anime_status AS tas ON ta.id = tas.anime_id
          WHERE ta.use_yn = 'Y'
    SQL

    args = []

    unless keyword.nil?
      sql += ' AND name LIKE ?'
      args << "%#{keyword}%"
    end

    unless status == 1
      case status
      when 32
        sql += 'GROUP BY ta.id, ta.name
                HAVING (COUNT(ta.id) > 0
                AND COUNT(ta.id) <= (SELECT COUNT(tas.id)))'
      when 2, 4
        sql += ' AND tas.status = ?'

        args << status
      when 3
        sql += ' AND tas.anime_id IS NULL'
      end
    end

    sql += ') AS a'

    count = db.execute(sql, args)

    count[0]['count']
  end

  def select_anime_status(db, id)
    sql = <<~SQL
      SELECT tas.current_episode, tas.completion_date, tc.name AS status
      FROM tb_anime_status tas
      LEFT JOIN tb_common tc ON tc.id = tas.status
      WHERE anime_id = ?
    SQL

    db.execute(sql, id)
  end

  def insert_anime_status(db, id)
    date = current_datetime

    sql = <<~SQL
      INSERT INTO tb_anime_status#{' '}
      (
       anime_id,
       insert_date
       )
      VALUES (?,?)
    SQL

    args = [id, date]

    db.execute(sql, args)
  end

  def update_anime_status(db, status, id)
    date = current_datetime

    sql = <<~SQL
      UPDATE tb_anime_status
      SET status = ?,
          update_date = ?
      WHERE anime_id = ?
    SQL

    args = [status, date, id]

    db.execute(sql, args)
  end

  def update_anime_current_episode(db, current_episode, id)
    date = current_datetime

    sql = <<~SQL
      UPDATE tb_anime_status
      SET current_episode = ?,
          update_date = ?
      WHERE anime_id = ?
    SQL

    args = [current_episode, date, id]

    db.execute(sql, args)
  end

  def update_anime_complete(db, id, completion_date = nil)
    date = current_datetime
    completion_date = current_date if completion_date.nil?

    sql = <<~SQL
      UPDATE tb_anime_status
      SET completion_date = ?,
          update_date = ?,
          current_episode = (SELECT a.episode
                             FROM tb_anime a
                             WHERE a.id =?),
          status = 32
      WHERE anime_id = ?
    SQL

    args = [completion_date, date, id, id]

    db.execute(sql, args)
  end

  def insert_anime(db, anime)
    date = current_datetime

    sql = <<~SQL
      INSERT INTO tb_anime
      (
       name,
       storage,
       media,
       studio,
       created_date,
       rip,
       ratio,
       episode,
       insert_date
       ) VALUES
       (?,?,?,?,?,?,?,?,?)
    SQL

    args = []
    args << anime.name
    args << anime.storage
    args << anime.media
    args << anime.studio.join(',')
    args << anime.created_date
    args << anime.rip
    args << anime.ratio.join(',')
    args << anime.episode
    args << date

    db.execute(sql, args)
    db.last_insert_row_id

  end

  def update_anime(db, anime)
    date = current_datetime

    sql = <<~SQL
      UPDATE tb_anime
      SET
       name =?,
       storage =?,
       media =?,
       studio =?,
       created_date =?,
       rip =?,
       ratio =?,
       episode =?,
       update_date =?
      WHERE id =?
    SQL

    args = []
    args << anime.name
    args << anime.storage
    args << anime.media
    args << anime.studio.join(',')
    args << anime.created_date
    args << anime.rip
    args << anime.ratio.join(',')
    args << anime.episode
    args << date
    args << anime.id

    db.execute(sql, args)

  end

  def delete_anime(db, id)
    date = current_datetime

    sql = <<~SQL
      UPDATE tb_anime
      SET
       use_yn = 'N',
       delete_date =?
      WHERE id =?
    SQL

    args = []
    args << date
    args << id

    db.execute(sql, args)

  end

  def check_duplicate_name(db, anime)
    sql = <<~SQL
      SELECT id
      FROM tb_anime
      WHERE name = ?
      AND media = ?
      AND studio = ?
      AND created_date = ?
      AND ratio = ?
      AND episode = ?
      AND use_yn = 'Y'
    SQL

    args = []
    args << anime.name
    args << anime.media
    args << anime.studio.join(',')
    args << anime.created_date
    args << anime.ratio.join(',')
    args << anime.episode

    col = db.execute(sql, args)

    !col.empty?

  end

  def check_others(db, anime)
    sql = <<~SQL
      SELECT count(*) AS count
      FROM tb_anime
      WHERE id = ?
      AND storage = ?
      AND rip = ?
      AND use_yn = 'Y'
    SQL

    args = []
    args << anime.id
    args << anime.storage
    args << anime.rip

    count = db.execute(sql, args)

    count[0]['count']
  end

  def select_all_anime_count(db)
    sql = <<~SQL
      SELECT COUNT(*) AS count
      FROM tb_anime
      WHERE use_yn = 'Y'
    SQL

    count = db.execute(sql)

    count[0]['count']
  end

  def select_current_status_by_group_id(db, group_id)
    sql = <<~SQL
      SELECT tas.status
      FROM tb_anime ta
      LEFT JOIN tb_map tm ON tm.from_tb = 'tb_group' AND tm.refer_id = ta.id
      LEFT JOIN tb_anime_status tas ON ta.id = tas.anime_id
      WHERE tm.from_id = ?
      AND ta.use_yn = 'Y'
      ORDER BY ta.created_date
    SQL

    args = [group_id]

    db.execute(sql, args)

  end

  def select_recommend_anime_by_group_id(db, group_id)
    sql = <<~SQL
      SELECT ta.id, ta.name
      FROM tb_anime ta
      LEFT JOIN tb_map tm ON tm.from_tb = 'tb_group' AND tm.refer_id = ta.id
      LEFT JOIN tb_anime_status tas ON ta.id = tas.anime_id
      WHERE tas.status is null AND ta.use_yn ='Y' AND tm.from_id = ?
      ORDER BY ta.created_date
      LIMIT 1
    SQL

    args = [group_id]

    db.execute(sql, args)
  end

end

AnimeMapper.instance
