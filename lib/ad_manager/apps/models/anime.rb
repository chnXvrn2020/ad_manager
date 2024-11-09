# frozen_string_literal: true

class Anime

  attr_accessor :id, :name, :storage, :media, :studio,
                :created_date, :rip, :ratio, :episode,
                :use_yn, :insert_date, :update_date, :delete_date,
                :current_episode, :completion_date, :status

  def initialize(anime)
    @id = anime['id']
    @name = anime['name']
    @storage = anime['storage']
    @media = anime['media']
    @studio = anime['studio']
    @created_date = anime['created_date']
    @rip = anime['rip']
    @ratio = anime['ratio']
    @episode = anime['episode']
    @use_yn = anime['use_yn']
    @insert_date = anime['insert_date']
    @update_date = anime['update_date']
    @delete_date = anime['delete_date']

    @current_episode = anime['current_episode']
    @completion_date = anime['completion_date']
    @status = anime['status']
  end

end
