# frozen_string_literal: true

class FileController
  @@img_path = './files/akiba_images/'

  def self.img_path
    @@img_path
  end

  def get_image_info(type, id)

    db = connect_to_db
    data = FilesMapper.instance.select_by_tb_and_id(db, type, id)
    db.close

    return nil if data.empty?

    Files.new(data[0])

  end

  def add_image_file(file)
    db = connect_to_db
    FilesMapper.instance.insert_file(db, file)
    db.close
  end

  def modify_image_file(file)
    db = connect_to_db
    data = FilesMapper.instance.select_by_tb_and_id(db, file.refer_tb, file.refer_id)

    File.delete("#{@@img_path}#{data[0]['file_name']}") unless data.empty?

    FilesMapper.instance.delete_file(db, file)
    FilesMapper.instance.insert_file(db, file)
    db.close
  end

  def delete_image_file(file)
    db = connect_to_db
    data = FilesMapper.instance.select_by_tb_and_id(db, file.refer_tb, file.refer_id)

    File.delete("#{@@img_path}#{data[0]['file_name']}")

    FilesMapper.instance.delete_file(db, file)
    db.close
  end

end
