# frozen_string_literal: true

require 'singleton'

class MapMapper
  include Singleton

  def select_content_mapping(db, id)
    sql = <<~SQL
      SELECT a.from_id AS content_id, b.refer_id AS group_id
      FROM tb_map a
               LEFT JOIN tb_map b ON a.from_tb = 'tb_content'
          AND a.refer_tb = 'tb_group'
          AND a.from_id = b.from_id
      WHERE a.from_tb = 'tb_content'
        AND b.refer_tb = 'tb_group'
        AND b.refer_id = ?
    SQL

    args = [id]

    db.execute(sql, args)

  end

  def select_group_mapping(db, type, id)
    sql = <<~SQL
      SELECT DISTINCT a.from_id AS group_id, b.refer_id AS id
      FROM tb_map a
               LEFT JOIN tb_map b ON a.from_tb = 'tb_group'
          AND a.refer_tb = ?
          AND a.from_id = b.from_id
      WHERE a.from_tb = 'tb_group'
        AND b.refer_tb = ?
        AND b.refer_id = ?
    SQL

    args = [type, type, id]

    db.execute(sql, args)
  end

  def insert_mapping(db, map)
    sql = <<~SQL
      INSERT INTO
      tb_map (
      from_tb,
      from_id,
      refer_tb,
      refer_id
      ) VALUES (
      ?,
      ?,
      ?,
      ?
      )
    SQL

    args = [map.from_tb, map.from_id, map.refer_tb, map.refer_id]

    db.execute(sql, args)

  end

  def delete_one_mapping(db, map)

    sql = <<~SQL
      DELETE FROM
      tb_map
       WHERE from_tb = ?
         AND from_id = ?
         AND refer_tb = ?
         AND refer_id = ?
    SQL

    args = [map.from_tb, map.from_id, map.refer_tb, map.refer_id]

    db.execute(sql, args)
  end

  def delete_group_mapping(db, id)
    sql = <<~SQL
      DELETE FROM tb_map
      WHERE (from_tb = 'tb_group' AND from_id = ?)
      OR (refer_tb = 'tb_group' AND refer_id = ?)
    SQL

    args = [id, id]

    db.execute(sql, args)
  end

end

MapMapper.instance
