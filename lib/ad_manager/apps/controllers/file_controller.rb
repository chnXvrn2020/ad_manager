# frozen_string_literal: true

class FileController

  # 画像情報取得
  def get_image_info(type, id)
    db = connect_to_db

    begin
      FileService.instance.get_image_info(db, type, id)
    rescue StandardError => e
      e.message
    ensure
      db.close
    end
  end

end
