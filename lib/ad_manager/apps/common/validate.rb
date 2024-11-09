# frozen_string_literal: true

def anime_validation
  anime = {}

  return :empty_title if @anime_title_entry.text.to_s.strip.empty?
  return :empty_storage if @storage_combo.active_iter[1].zero?
  return :empty_media if @media_combo.active_iter[1].zero?
  return :empty_rip if @rip_combo.active_iter[1].zero?

  ratio = []

  @ratio_box.children.each do |child|
    ratio << child.name.to_i if child.active?
  end

  return :empty_ratio if ratio.empty?
  return :empty_date if @anime_date_entry.text.to_s.strip.empty?
  return :empty_episode if @anime_episode_entry.text.to_s.strip.empty?

  company = []

  @company_ides.each do |item|
    company << item
  end

  return :empty_studio if company.empty?

  anime['name'] = @anime_title_entry.text
  anime['storage'] = @storage_combo.active_iter[1]
  anime['media'] = @media_combo.active_iter[1]
  anime['rip'] = @rip_combo.active_iter[1]
  anime['ratio'] = ratio
  anime['created_date'] = @anime_date_entry.text
  anime['episode'] = @anime_episode_entry.text.to_i
  anime['studio'] = company

  anime
end

def book_validation
  book = {}

  return :empty_title if @book_title_entry.text.to_s.strip.empty?
  return :empty_date if @book_date_entry.text.to_s.strip.empty?

  company = []

  @company_ides.each do |item|
    company << item
  end

  return :empty_publisher if company.empty?

  book['name'] = @book_title_entry.text
  book['type'] = @selected_group_original_combo.active_iter[1]
  book['created_date'] = @book_date_entry.text
  book['publisher'] = company

  book
end
