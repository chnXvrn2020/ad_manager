# frozen_string_literal: true

require_relative '../../controllers/common_controller'
require_relative '../../controllers/anime_controller'
require_relative '../../controllers/company_controller'

require 'gtk3'

class TableSearch < Gtk::Dialog

  attr_reader :keyword

  # 初期化
  def initialize(parent, menu)
    super(title: menu, parent: parent,
          flags: %i[modal destroy_with_parent])
    set_size_request(1000, 700)
    set_position(Gtk::WindowPosition::CENTER)

    self.deletable = false
    self.resizable = false

    @menu = menu
    @ides = []
    @type = nil
    @param = []
    @common_controller = CommonController.new
    @anime_controller = AnimeController.new
    @company_controller = CompanyController.new

    set_ui
    set_signal_connect

    show_all
    set_visible(true, false, false)
  end

  private

  # UIの設定
  def set_ui
    child.set_margin_start(75)
    child.set_margin_end(75)
    child.set_margin_top(25)
    child.set_margin_bottom(25)

    h_box = Gtk::Box.new(:horizontal)
    child.pack_start(h_box, padding: 10)

    @entry = Gtk::Entry.new
    @entry.set_size_request(800, 35)
    @entry.grab_focus
    h_box.pack_start(@entry, expand: true)

    @original_combo = Gtk::ComboBoxText.new
    @original_combo.set_size_request(150, 35)
    h_box.pack_start(@original_combo)

    set_combo_box
    no_original
    anime_original
    book_original

    bottom_h_box = Gtk::Box.new(:horizontal)
    child.pack_start(bottom_h_box, padding: 10)

    @search_btn = Gtk::Button.new(label: I18n.t('menu.search'))
    @search_btn.set_size_request(400, 50)
    bottom_h_box.pack_start(@search_btn, expand: true)

    @close_btn = Gtk::Button.new(label: I18n.t('menu.close'))
    @close_btn.set_size_request(400, 50)
    bottom_h_box.pack_start(@close_btn, expand: true)
  end

  # ウィゼットの設定
  def set_signal_connect
    # 原作コンボボックスの変更イベント
    @original_combo.signal_connect('changed') do |combo|
      # 種別によって分岐し、表示を切り替える
      case combo.active_iter[0]
      when I18n.t('original.anime')
        set_visible(false, true, false, 'studio')
      when I18n.t('original.manga'), I18n.t('original.novel')
        set_visible(false, false, true, 'publisher')
      when I18n.t('menu.original')
        set_visible(true, false, false)
        @no_original_label.text = I18n.t('table_search.no_original')
      else
        set_visible(true, false, false)
        @no_original_label.text = I18n.t('table_search.no_support')
      end
    end

    # 検索ボタンのクリックイベント
    @search_btn.signal_connect('clicked') do

    end

    # 閉じるボタンのクリックイベント
    @close_btn.signal_connect('clicked') do
      response(Gtk::ResponseType::CANCEL)
      destroy
    end
  end

  # コンボボックスの設定
  def set_combo_box
    text_renderer = Gtk::CellRendererText.new
    combo_model = Gtk::ListStore.new(String, Integer)

    original = @common_controller.get_type_menu('original')

    if original.is_a?(String)
       dialog_message(@window, :error, :db_error, original)
       return
    end

    primary = combo_model.append
    primary[0] = I18n.t('menu.original')
    primary[1] = 0

    original.each do |item|
      iter = combo_model.append
      iter[0] = item.name
      iter[1] = item.id
    end

    @original_combo.clear
    @original_combo.model = combo_model
    @original_combo.pack_start(text_renderer, true)
    @original_combo.set_attributes(text_renderer, text: 0)
    @original_combo.active = 0
  end

  # 表示できないときのUIの設定
  def no_original
    @no_original_main_box = Gtk::Box.new(:vertical)
    child.pack_start(@no_original_main_box, expand: true)

    @no_original_label = Gtk::Label.new(I18n.t('table_search.no_original'))
    @no_original_main_box.pack_start(@no_original_label)
  end

  # アニメのUIの設定
  def anime_original
    @anime_original_main_box = Gtk::Box.new(:vertical)
    child.pack_start(@anime_original_main_box, expand: true)

    first_h_box = Gtk::Box.new(:horizontal)
    @anime_original_main_box.pack_start(first_h_box)

    @storage_combo = Gtk::ComboBoxText.new
    @storage_combo.set_size_request(150, 35)
    first_h_box.pack_start(@storage_combo, expand: true)

    @media_combo = Gtk::ComboBoxText.new
    @media_combo.set_size_request(150, 35)
    first_h_box.pack_start(@media_combo, expand: true)

    @rip_combo = Gtk::ComboBoxText.new
    @rip_combo.set_size_request(150, 35)
    first_h_box.pack_start(@rip_combo, expand: true)

    ratio_group = Gtk::Frame.new
    first_h_box.pack_start(ratio_group, expand: true)

    @ratio_box = Gtk::Box.new(:horizontal)
    ratio_group.add(@ratio_box)

    @anime_date_combo = Gtk::ComboBoxText.new
    @anime_date_combo.set_size_request(150, 35)
    first_h_box.pack_start(@anime_date_combo, expand: true)

    first_v_box = Gtk::Box.new(:vertical)
    @anime_original_main_box.pack_start(first_v_box, padding: 25)

    company_label = Gtk::Label.new(I18n.t('table_search.company'))
    first_v_box.pack_start(company_label)

    second_h_box = Gtk::Box.new(:horizontal)
    first_v_box.pack_start(second_h_box, padding: 25)

    @company_entry = Gtk::Entry.new
    @company_entry.set_size_request(850, 10)
    second_h_box.pack_start(@company_entry)

    @company_search_btn = Gtk::Button.new(label: I18n.t('menu.search'))
    @company_search_btn.set_size_request(100, 35)
    second_h_box.pack_start(@company_search_btn)

    list_h_box = Gtk::Box.new(:horizontal)
    @anime_original_main_box.pack_start(list_h_box)

    selected_list_v_box = Gtk::Box.new(:vertical)
    list_h_box.pack_start(selected_list_v_box, expand: true)

    selected_label = Gtk::Label.new
    selected_label.text = I18n.t('company.selected')
    selected_list_v_box.pack_start(selected_label)

    @selected_list_scroll = Gtk::ScrolledWindow.new
    @selected_list_scroll.set_size_request(400, 300)
    selected_list_v_box.pack_start(@selected_list_scroll, expand: true)

    @selected_list = Gtk::ListBox.new
    @selected_list_scroll.add(@selected_list)

    company_list_v_box = Gtk::Box.new(:vertical)
    list_h_box.pack_start(company_list_v_box, expand: true)

    company_label = Gtk::Label.new
    company_label.text = I18n.t('company.not_selected')
    company_list_v_box.pack_start(company_label)

    @company_list_scroll = Gtk::ScrolledWindow.new
    @company_list_scroll.set_size_request(400, 300)
    company_list_v_box.pack_start(@company_list_scroll, expand: true)

    @company_list = Gtk::ListBox.new
    @company_list_scroll.add(@company_list)

    load_anime_frame_data
    set_anime_connect
  end

  # アニメのフレームのデータを読み込む
  def load_anime_frame_data
    common = %w[storage media rip ratio year]

    common.each do |item|
      result = if item == 'year'
                 @anime_controller.get_anime_year_group_list
               else
                 @common_controller.get_type_menu(item)
               end

      if result.is_a?(String)
        dialog_message(@window, :error, :db_error, result)
        next
      end

      text_renderer = Gtk::CellRendererText.new
      combo_model = Gtk::ListStore.new(String, Integer)

      # 種別に応じたデータを読み込む
      # storage：ストレージ
      # media：メディア
      # rip：リップ
      # ratio：比率
      # year：年代
      case item
      when 'storage'
        primary = combo_model.append
        primary[0] = I18n.t('table_search.storage')
        primary[1] = 0
      when 'media'
        primary = combo_model.append
        primary[0] = I18n.t('table_search.media')
        primary[1] = 0
      when 'rip'
        primary = combo_model.append
        primary[0] = I18n.t('table_search.rip')
        primary[1] = 0
      when 'year'
        primary = combo_model.append
        primary[0] = I18n.t('table_search.year')
        primary[1] = 0
      end

      if item == 'ratio'
        result.each do |item2|
          ratio_check = Gtk::CheckButton.new
          ratio_check.label = item2.name
          ratio_check.name = item2.id.to_s
          @ratio_box.pack_start(ratio_check)
        end
      elsif item == 'year'
        result.each do |item2|
          iter = combo_model.append
          iter[0] = item2['year_group']
        end
      else
        result.each do |item2|
          iter = combo_model.append
          iter[0] = item2.name
          iter[1] = item2.id
        end
      end

      case item
      when 'storage'
        @storage_combo.clear
        @storage_combo.model = combo_model
        @storage_combo.pack_start(text_renderer, true)
        @storage_combo.set_attributes(text_renderer, text: 0)
        @storage_combo.active = 0
      when 'media'
        @media_combo.clear
        @media_combo.model = combo_model
        @media_combo.pack_start(text_renderer, true)
        @media_combo.set_attributes(text_renderer, text: 0)
        @media_combo.active = 0
      when 'rip'
        @rip_combo.clear
        @rip_combo.model = combo_model
        @rip_combo.pack_start(text_renderer, true)
        @rip_combo.set_attributes(text_renderer, text: 0)
        @rip_combo.active = 0
      when 'year'
        @anime_date_combo.clear
        @anime_date_combo.model = combo_model
        @anime_date_combo.pack_start(text_renderer, true)
        @anime_date_combo.set_attributes(text_renderer, text: 0)
        @anime_date_combo.active = 0
      end
    end
  end

  # アニメのUIのウィゼットの設定
  def set_anime_connect
    # 制作会社の検索ボタンのクリックイベント
    @company_search_btn.signal_connect('clicked') do
      if @company_entry.text.to_s.strip.empty?
        dialog_message(self, :warning, :empty_entry)
        @company_entry.grab_focus

        next
      end
      load_company_data(@company_list, @company_list_scroll, @company_entry)
    end

    # 制作会社のリストボックスのダブルクリックイベント
    @company_list.signal_connect('button_press_event') do |widget, event|
      if event.type == Gdk::EventType::BUTTON2_PRESS
        selected_row = widget.selected_row

        if selected_row
          company_id = selected_row.name.to_i
          @ides << company_id

          load_selected_company(@selected_list, @selected_list_scroll)
          load_company_data(@company_list, @company_list_scroll, @company_entry)
        end
      end
    end
  end

  # 書籍のUIの設定
  def book_original
    @book_original_main_box = Gtk::Box.new(:vertical)
    child.pack_start(@book_original_main_box, expand: true)
  end

  # 各UIの表示・非表示の切り替え
  def set_visible(no, anime, book, type = nil)
    @no_original_main_box.visible = no
    @anime_original_main_box.visible = anime
    @book_original_main_box.visible = book
    @type = type
  end

  # 会社のデータを読み込む
  def load_company_data(list, scroll, entry)
    clear_list_box(list)

    keyword = entry.text.to_s.strip

    company = @company_controller.get_all_company_list(@type, @ides, keyword)

    if company.is_a?(String)
      dialog_message(self, :error, :db_error, company)
      return
    end

    company.each do |item|
      row = Gtk::ListBoxRow.new
      row.add(Gtk::Label.new(item.name))
      row.name = item.id.to_s

      list.add(row)
    end

    scroll.vadjustment.value = 0.0
    list.show_all
  end

  # 選択されてる会社のデータを読み込む
  def load_selected_company(list, scroll)
    clear_list_box(list)
    @param = []

    return if @ides.empty?

    selected_company = []

    begin
      @ides.each do |company_id|
        selected_company << @company_controller.get_one_company(company_id)
      end
    rescue StandardError => e
      dialog_message(self, :error, :db_error, e.message)
      return
    end

    selected_company.each do |item|
      row = Gtk::ListBoxRow.new
      row.add(Gtk::Label.new(item.name))
      row.name = item.id.to_s

      list.add(row)

      @param << { 'name' => item.name, 'id' => item.id }
    end

    scroll.vadjustment.value = 0.0
    list.show_all
  end
end
