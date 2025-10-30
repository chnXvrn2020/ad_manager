# frozen_string_literal: true

require 'singleton'

class AnimeService
  include Singleton

  def add_anime(db, anime)
    duplicate_check = AnimeMapper.instance.check_duplicate_name(db, anime)

    return nil if duplicate_check

    last_id = AnimeMapper.instance.insert_anime(db, anime)

    return nil if last_id.nil?

    last_id
  end

  def set_mapping_anime(db, group_id, anime_id)
    param = {
      from_tb: 'tb_group',
      from_id: group_id,
      refer_tb: 'tb_anime',
      refer_id: anime_id
    }

    map = create_map(param)

    MapMapper.instance.insert_mapping(db, map)
  end

  def remove_mapping_anime(db, group_id, anime_id)
    param = {
      from_tb: 'tb_group',
      from_id: group_id,
      refer_tb: 'tb_anime',
      refer_id: anime_id
    }

    map = create_map(param)

    MapMapper.instance.delete_one_mapping(db, map)
  end

  def get_anime_list(db, group_id, keyword)
    AnimeMapper.instance.select_anime_list_by_group_id(db, group_id, keyword)
  end

  def get_unselected_anime_list(db, group_id, keyword)
    AnimeMapper.instance.select_unselected_anime_list_by_group_id(db, group_id, keyword)
  end

  def get_anime_status(db, id)
    AnimeMapper.instance.select_anime_status(db, id)
  end

  def start_watching_anime(db, id)
    AnimeMapper.instance.insert_anime_status(db, id)
    AnimeMapper.instance.select_anime_status(db, id)
  end

  def modify_watching_anime(db, status, id)
    AnimeMapper.instance.update_anime_status(db, status, id)
    AnimeMapper.instance.select_anime_status(db, id)
  end

  def modify_anime_current_episode(db, current_episode, id)
    AnimeMapper.instance.update_anime_current_episode(db, current_episode, id)
  end

  def complete_watching_anime(db, id, completion_date)
    AnimeMapper.instance.update_anime_complete(db, id, completion_date)
    AnimeMapper.instance.select_anime_status(db, id)
  end

  def get_anime_list_with_count(db, keyword, status, current_page)
    count = AnimeMapper.instance.select_all_count(db, keyword, status)
    page = Page.new(count, current_page)
    anime = AnimeMapper.instance.select_all(db, page, keyword, status)

    model = []

    anime.each do |hash|
      model << Anime.new(hash)
    end

    { 'model' => model, 'page' => page }
  end

  def get_anime_by_id(db, id)
    AnimeMapper.instance.select_anime_by_id(db, id)
  end

  def get_anime_info_by_id(db, id)
    anime = AnimeMapper.instance.select_anime_by_id(db, id)
    status = AnimeMapper.instance.select_anime_status(db, id)

    return { 'anime' => Anime.new(anime[0]), 'status' => nil } if status.empty?

    { 'anime' => Anime.new(anime[0]), 'status' => Anime.new(status[0]) }
  end

  def modify_anime(db, anime)
    if AnimeMapper.instance.check_duplicate_name(db, anime) &&
       AnimeMapper.instance.check_others(db, anime) >= 1
      return false
    end

    AnimeMapper.instance.update_anime(db, anime)

    true
  end

  def remove_anime(db, id)
    AnimeMapper.instance.delete_anime(db, id)
  end

  def recommend_anime(db)
    content = ContentMapper.instance.select_all_content_with_group(db)
    loop do
      content_array = []

      content.each do |data|
        content_array << Content.new(data)
      end

      rand_content = content_array.sample

      group_list = GroupMapper.instance.select_group_list_by_content_id(db, rand_content.id)

      group_array = []

      group_list.each do |data|
        group_array << Group.new(data)
      end

      group_array.each do |group|
        status = AnimeMapper.instance.select_current_status_by_group_id(db, group.id)

        next unless status_loop(status).zero?

        recommend_data = AnimeMapper.instance.select_recommend_anime_by_group_id(db, group.id)

        anime = Anime.new(recommend_data[0])

        recommend = {
          'content_id' => rand_content.id,
          'anime_content_data' => rand_content.name,
          'group_id' => group.id,
          'anime_group_data' => group.name,
          'recommend_id' => anime.id,
          'recommend_name' => anime.name
        }

        return recommend
      end

    end

  end

  def get_anime_year_group_list(db)
    AnimeMapper.instance.select_anime_year_group(db)
  end

end

AnimeService.instance
