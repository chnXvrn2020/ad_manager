# frozen_string_literal: true

require 'singleton'

class FilesMapper
  include Singleton

  def select_by_tb_and_id(db, tb_name, id)
    sql = <<~SQL
      SELECT *
      FROM tb_files
      WHERE refer_tb = ?
      AND refer_id = ?
      AND use_yn = 'Y'
    SQL
    args = [tb_name, id]

    db.execute(sql, args)

  end

  def insert_file(db, files)
    date = current_datetime

    sql = <<~SQL
      INSERT INTO tb_files (
        refer_tb,
        refer_id,
        file_name,
        insert_date
        )
      VALUES (?,?,?,?)
    SQL

    args = [files.refer_tb, files.refer_id, files.file_name, date]

    db.execute(sql, args)

  end

  def delete_file(db, files)
    date = current_datetime

    sql = <<~SQL
      UPDATE tb_files
      SET
          use_yn = 'N',
          delete_date = ?
      WHERE refer_tb =?
      AND refer_id =?
    SQL
    args = [date, files.refer_tb, files.refer_id]

    db.execute(sql, args)

  end

end

FilesMapper.instance
