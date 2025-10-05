# frozen_string_literal: true

require 'singleton'
class FileService
  include Singleton

  def add_image_file(db, file)
    FilesMapper.instance.insert_file(db, file)
  end

  def get_image_file(db, type, id)
    data = FilesMapper.instance.select_by_tb_and_id(db, type, id)

    return nil if data.empty?

    Files.new(data[0])
  end

  def modify_image_file(db, img)
    return if img['img_file_name'].nil?

    file = file_upload(img['img_file_name'], img['content_type'], img['content_id'])

    data = FilesMapper.instance.select_by_tb_and_id(db, file.refer_tb, file.refer_id)

    File.delete("#{img_path}#{data[0]['file_name']}") unless data.empty?

    FilesMapper.instance.delete_file(db, file)
    FilesMapper.instance.insert_file(db, file)
  end

  def delete_image_file(db, file)
    data = FilesMapper.instance.select_by_tb_and_id(db, file.refer_tb, file.refer_id)

    return if data.empty?

    File.delete("#{img_path}#{data[0]['file_name']}")
    FilesMapper.instance.delete_file(db, file)

  end

  def get_image_info(db, type, id)
    data = FilesMapper.instance.select_by_tb_and_id(db, type, id)

    return nil if data.empty?

    Files.new(data[0])
  end

end

FileService.instance
