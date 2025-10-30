# frozen_string_literal: true

class AnimeController

  # アニメの追加
  def add_anime(param)
    db = connect_to_db

    begin
      db.transaction
      last_id = AnimeService.instance.add_anime(db, param[:anime])
      raise if last_id.nil?

      file = file_upload(param[:img_file_name], param[:content_type], last_id)

      FileService.instance.add_image_file(db, Files.new(file)) unless file.nil?
      AnimeService.instance.set_mapping_anime(db, param[:group_id], last_id)

      db.commit
    rescue StandardError => e
      db.rollback
      File.delete("#{img_path}#{file["file_name"]}") unless file.nil?
      return e.message
    ensure
      db.close
    end

    true
  end

  # グループ別に既存のアニメを追加する
  def set_mapping_anime(group_id, anime_id)
    db = connect_to_db

    begin
      AnimeService.instance.set_mapping_anime(db, group_id, anime_id)
    rescue StandardError => e
      return e.message
    ensure
      db.close
    end

    true
  end

  # グループ別に既存のアニメを除外する
  def remove_mapping_anime(group_id, anime_id)
    db = connect_to_db

    begin
      AnimeService.instance.remove_mapping_anime(db, group_id, anime_id)
    rescue StandardError => e
      return e.message
    ensure
      db.close
    end

    true
  end

  # グループ別に追加されてるアニメ情報のリストを呼び出す
  def get_anime_list(group_id, keyword = nil)
    db = connect_to_db
    data = begin
             AnimeService.instance.get_anime_list(db, group_id, keyword)
    rescue StandardError => e
             return e.message
    ensure
             db.close
    end

    anime = []

    data.each do |hash|
      anime << Anime.new(hash)
    end

    anime
  end

  # グループ別に追加されてないアニメ情報のリストを呼び出す
  def get_unselected_anime_list(group_id, keyword = nil)
    db = connect_to_db

    data = begin
             AnimeService.instance.get_unselected_anime_list(db, group_id, keyword)
    rescue StandardError => e
             return e.message
    ensure
             db.close
    end

    anime = []

    data.each do |hash|
      anime << Anime.new(hash)
    end

    anime
  end

  # アニメの視聴を始める
  def start_watching_anime(id)
    db = connect_to_db
    data = {}

    begin
      db.transaction
      data = AnimeService.instance.start_watching_anime(db, id)
      db.commit
    rescue StandardError => e
      db.rollback
      return e.message
    ensure
      db.close
    end

    return nil if data.empty?

    Anime.new(data[0])
  end

  # 視聴中のアニメの状態を変更する
  def modify_watching_anime(type, id)
    status = 4 if type == :anime_stop
    status = 2 if type == :anime_restart

    db = connect_to_db
    data = {}

    begin
      db.transaction
      data = AnimeService.instance.modify_watching_anime(db, status, id)
      db.commit
    rescue StandardError => e
      db.rollback
      return e.message
    ensure
      db.close
    end

    return nil if data.empty?

    Anime.new(data[0])
  end

  # 視聴中のアニメの現在のエピソードを変更する
  def modify_anime_current_episode(current_episode, id)
    db = connect_to_db

    begin
      AnimeService.instance.modify_anime_current_episode(db, current_episode, id)
    rescue StandardError => e
      return e.message
    ensure
      db.close
    end

    true
  end

  # 視聴中のアニメをコンプリする
  def complete_watching_anime(id, completion_date = nil)
    db = connect_to_db
    data = {}

    begin
      db.transaction
      data = AnimeService.instance.complete_watching_anime(db, id, completion_date)
      db.commit
    rescue StandardError => e
      db.rollback
      return e.message
    ensure
      db.close
    end

    return nil if data.empty?

    Anime.new(data[0])
  end

  # アニメ情報をカウントとともにリストとして呼び出す
  def get_anime_list_with_count(current_page = 1, keyword = nil, status = nil)
    db = connect_to_db

    begin
      AnimeService.instance.get_anime_list_with_count(db, keyword, status, current_page)
    rescue StandardError => e
      e.message
    ensure
      db.close
    end
  end

  # アニメをIDで呼び出す
  def get_anime_by_id(id)
    db = connect_to_db

    begin
      data = AnimeService.instance.get_anime_by_id(db, id)
    rescue StandardError => e
      return e.message
    ensure
      db.close
    end

    Anime.new(data[0])
  end

  # アニメ情報をIDで呼び出す
  def get_anime_info_by_id(type, id)
    db = connect_to_db

    begin
      anime_info = AnimeService.instance.get_anime_info_by_id(db, id)
      anime_file = FileService.instance.get_image_file(db, type, id)

      anime_info.merge!("file" => anime_file)
    rescue StandardError => e
      return e.message
    ensure
      db.close
    end

    anime_info
  end

  # アニメ情報を変更する
  def modify_anime(anime, img)
    db = connect_to_db

    begin
      db.transaction

      result = AnimeService.instance.modify_anime(db, anime)
      return false unless result

      # 画像の変更
      # 画像が削除された場合はファイルを削除する
      if img['img_del'] == 'Y'
        file = {}

        file['refer_tb'] = img['content_type']
        file['refer_id'] = img['content_id']

        FileService.instance.delete_image_file(db, Files.new(file))
      else
        FileService.instance.modify_image_file(db, img)
      end

      db.commit
    rescue StandardError => e
      db.rollback
      return e.message
    ensure
      db.close
    end

    true
  end

  # アニメ情報を削除する
  def remove_anime(id, file)
    db = connect_to_db

    begin
      db.transaction
      AnimeService.instance.remove_anime(db, id)
      FileService.instance.delete_image_file(db, file)
      db.commit
    rescue StandardError => e
      db.rollback
      return e.message
    ensure
      db.close
    end

    true
  end

  # アニメを推薦する
  def recommend_anime
    db = connect_to_db

    begin
      AnimeService.instance.recommend_anime(db)
    rescue StandardError => e
      e.message
    ensure
      db.close
    end
  end

  # アニメの年代をごとに呼び出す
  def get_anime_year_group_list
    db = connect_to_db

    begin
      AnimeService.instance.get_anime_year_group_list(db)
    rescue StandardError => e
      e.message
    ensure
      db.close
    end
  end

end
