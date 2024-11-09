# frozen_string_literal: true

class AnimeController

  def add_anime(anime)
    db = connect_to_db

    if AnimeMapper.instance.check_duplicate_name(db, anime)
      db.close
      return nil
    end

    last_id = AnimeMapper.instance.insert_anime(db, anime)

    db.close

    last_id
  end

  def set_mapping_anime(group_id, anime_id)
    from_tb = 'tb_group'
    refer_tb = 'tb_anime'

    map = Map.new({'from_tb' => from_tb,
                   'from_id' => group_id,
                   'refer_tb' => refer_tb,
                   'refer_id' => anime_id})

    db = connect_to_db
    MapMapper.instance.insert_mapping(db, map)
    db.close
  end

  def remove_mapping_anime(group_id, anime_id)
    from_tb = 'tb_group'
    refer_tb = 'tb_anime'

    map = Map.new({'from_tb' => from_tb,
                   'from_id' => group_id,
                   'refer_tb' => refer_tb,
                   'refer_id' => anime_id})

    db = connect_to_db
    MapMapper.instance.delete_one_mapping(db, map)
    db.close
  end

  def get_anime_list(group_id, keyword = nil)
    db = connect_to_db
    data = AnimeMapper.instance.select_anime_list_by_group_id(db, group_id, keyword)
    db.close

    anime = []

    data.each do |hash|
      anime << Anime.new(hash)
    end

    anime

  end

  def get_unselected_anime_list(group_id, keyword = nil)
    db = connect_to_db
    data = AnimeMapper.instance.select_unselected_anime_list_by_group_id(db, group_id, keyword)
    db.close

    anime = []

    data.each do |hash|
      anime << Anime.new(hash)
    end

    anime
  end

  def get_anime_status(id)
    db = connect_to_db
    data = AnimeMapper.instance.select_anime_status(db, id)
    db.close

    return nil if data.empty?

    Anime.new(data[0])
  end

  def start_watching_anime(id)
    db = connect_to_db
    AnimeMapper.instance.insert_anime_status(db, id)
    db.close
  end

  def modify_watching_anime(status, id)
    db = connect_to_db
    AnimeMapper.instance.update_anime_status(db, status, id)
    db.close
  end

  def modify_anime_current_episode(current_episode, id)
    db = connect_to_db
    AnimeMapper.instance.update_anime_current_episode(db, current_episode, id)
    db.close
  end

  def complete_watching_anime(id, completion_date = nil)
    db = connect_to_db
    AnimeMapper.instance.update_anime_complete(db, id, completion_date)
    db.close
  end

  def get_anime_list_with_count(current_page = 1, keyword = nil, status = nil)
    db = connect_to_db
    count = AnimeMapper.instance.select_all_count(db, keyword, status)
    page = Page.new(count, current_page)
    anime = AnimeMapper.instance.select_all(db, page, keyword, status)
    db.close

    # content_sort(anime) unless status == 32 || status.nil?

    model = []

    anime.each do |hash|
      model << Anime.new(hash)
    end

    { 'model' => model, 'page' => page }
  end

  def get_anime_by_id(id)
    db = connect_to_db
    data = AnimeMapper.instance.select_anime_by_id(db, id)
    db.close

    Anime.new(data[0])
  end

  def modify_anime(anime)
    db = connect_to_db

    if AnimeMapper.instance.check_duplicate_name(db, anime) &&
      AnimeMapper.instance.check_others(db, anime) >= 1
      db.close
      return false
    end

    AnimeMapper.instance.update_anime(db, anime)
    db.close

    true
  end

  def remove_anime(id)
    db = connect_to_db
    AnimeMapper.instance.delete_anime(db, id)
    db.close
  end

  def get_current_status(group_id)
    db = connect_to_db
    data = AnimeMapper.instance.select_current_status_by_group_id(db, group_id)
    db.close

    data
  end

  def recommend_anime(group_id)
    db = connect_to_db
    data = AnimeMapper.instance.select_recommend_anime_by_group_id(db, group_id)
    db.close

    Anime.new(data[0])
  end

end
