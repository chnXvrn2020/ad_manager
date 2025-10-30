# frozen_string_literal: true

require_relative '../../../controllers/file_controller'
require_relative 'group_selector'
require_relative 'company_selector'
require_relative 'image_edit'
require_relative 'content_search'
require_relative 'data_selector'

class ContentIndex
  attr_reader :frame

  # 初期化
  def initialize(window, stack)
    @window = window
    @stack = stack
    @frame = Gtk::Frame.new
    @content_controller = ContentController.new
    @group_controller = GroupController.new
    @common_controller = CommonController.new
    @anime_controller = AnimeController.new
    @file_controller = FileController.new
    @company_controller = CompanyController.new
    @book_controller = BookController.new
    @id = nil
    @group_id = nil
    @content_id = nil
    @company_type = nil
    @content_type = nil
    @img_file = nil
    @img_del = 'N'
    @img_file_name = nil
    @keyword = nil
    @company_ides = []
    @text_renderer = Gtk::CellRendererText.new
    @anime = 'tb_anime'
    @book = 'tb_book'

    set_ui
    set_signal_connect
    initialize_window
  end

  # UIの初期化
  def initialize_ui(id)
    @id = id

    content = @content_controller.get_one_content(id)

    if content.is_a?(String)
      dialog_message(@window, :error, :db_error, content)
      return
    end

    @content_title.text = content.name
    @no_data_label.text = I18n.t('content.select_group')
    @selected_group_label.text = I18n.t('content.group_name')
    @selected_group_original_combo.active = 0
    @selected_group_original_combo.sensitive = false

    initialize_no_data
    initialize_anime_data
    initialize_book_data
    clear_common_data
    load_group_list
  end

  # フレイムの初期化
  def initialize_window
    initialize_no_data
    initialize_anime_data
    initialize_book_data
  end

  private

  # UIの設定
  def set_ui
    @main_v_box = Gtk::Box.new(:vertical)
    @main_v_box.set_margin_start(50)
    @main_v_box.set_margin_end(50)
    @main_v_box.set_margin_top(15)
    @main_v_box.set_margin_bottom(15)
    @frame.add(@main_v_box)

    title_v_box = Gtk::Box.new(:vertical)
    @main_v_box.pack_start(title_v_box, padding: 5)

    title_h_box = Gtk::Box.new(:horizontal)
    title_h_box.set_margin_start(50)
    title_h_box.set_margin_end(50)
    title_v_box.pack_start(title_h_box)

    @content_title = Gtk::Entry.new
    @content_title.set_size_request(700, 30)
    title_h_box.pack_start(@content_title, expand: true)

    @content_edit = Gtk::Button.new(label: I18n.t('menu.modify'))
    @content_edit.set_size_request(100, 30)
    title_h_box.pack_start(@content_edit)

    @content_remove = Gtk::Button.new(label: I18n.t('menu.remove'))
    @content_remove.set_size_request(100, 30)
    title_h_box.pack_start(@content_remove)

    @selected_group_h_box = Gtk::Box.new(:horizontal)
    @selected_group_h_box.set_margin_start(50)
    @selected_group_h_box.set_margin_end(50)
    title_v_box.pack_start(@selected_group_h_box, padding: 10)

    @selected_group_label = Gtk::Label.new(I18n.t('content.group_name'))
    @selected_group_h_box.pack_start(@selected_group_label)

    @selected_group_original_combo = Gtk::ComboBoxText.new
    @selected_group_original_combo.set_size_request(120, 50)
    @selected_group_h_box.pack_end(@selected_group_original_combo)

    load_original_combo

    no_data
    anime_data
    book_data
    data_group_frame
    bottom_btn_frame
  end

  # 選択されてないときのUIの設定
  def no_data
    @no_data_main_box = Gtk::Box.new(:vertical)
    @main_v_box.pack_start(@no_data_main_box, expand: true)

    @no_data_label = Gtk::Label.new(I18n.t('content.select_group'))
    @no_data_main_box.pack_start(@no_data_label)
  end

  # アニメが選択だれた時のUIの設定
  def anime_data
    @anime_data_main_box = Gtk::Box.new(:horizontal)
    @anime_data_main_box.set_margin_start(50)
    @anime_data_main_box.set_margin_end(50)
    @main_v_box.pack_start(@anime_data_main_box, expand: true)

    anime_info_v_box = Gtk::Box.new(:vertical)
    @anime_data_main_box.pack_start(anime_info_v_box, expand: true)

    @anime_title_entry = Gtk::Entry.new
    @anime_title_entry.set_size_request(450, 50)
    @anime_title_entry.placeholder_text = I18n.t('content.name_placeholder')
    anime_info_v_box.pack_start(@anime_title_entry, expand: true)

    anime_info_h_box1 = Gtk::Box.new(:horizontal)
    anime_info_v_box.pack_start(anime_info_h_box1)

    @storage_combo = Gtk::ComboBoxText.new
    @storage_combo.set_size_request(150, 50)
    anime_info_h_box1.pack_start(@storage_combo, expand: true)

    @media_combo = Gtk::ComboBoxText.new
    @media_combo.set_size_request(150, 50)
    anime_info_h_box1.pack_start(@media_combo, expand: true)

    @rip_combo = Gtk::ComboBoxText.new
    @rip_combo.set_size_request(150, 50)
    anime_info_h_box1.pack_start(@rip_combo, expand: true)

    anime_info_h_box2 = Gtk::Box.new(:horizontal)
    anime_info_v_box.pack_start(anime_info_h_box2, expand: true)

    ratio_group = Gtk::Frame.new
    anime_info_h_box2.pack_start(ratio_group)

    @ratio_box = Gtk::Box.new(:horizontal)
    ratio_group.add(@ratio_box)

    @anime_date_entry = Gtk::Entry.new
    @anime_date_entry.set_size_request(150, 35)
    @anime_date_entry.placeholder_text = I18n.t('content.date_placeholder')
    anime_info_h_box2.pack_start(@anime_date_entry)

    @anime_episode_entry = Gtk::Entry.new
    @anime_episode_entry.set_size_request(150, 35)
    @anime_episode_entry.placeholder_text = I18n.t('content.episode_placeholder')
    anime_info_h_box2.pack_start(@anime_episode_entry)

    anime_info_h_box3 = Gtk::Box.new(:horizontal)
    anime_info_v_box.pack_start(anime_info_h_box3, expand: true)

    @company_manage_btn = Gtk::Button.new(label: I18n.t('content.studio_management'))
    @company_manage_btn.set_size_request(225, 40)
    anime_info_h_box3.pack_start(@company_manage_btn, expand: true)

    @anime_image_btn = Gtk::Button.new(label: I18n.t('content.image_management'))
    @anime_image_btn.set_size_request(225, 40)
    anime_info_h_box3.pack_start(@anime_image_btn, expand: true)

    anime_info_h_box4 = Gtk::Box.new(:horizontal)
    anime_info_v_box.pack_start(anime_info_h_box4)

    @anime_add_btn = Gtk::Button.new(label: I18n.t('menu.add'))
    @anime_add_btn.set_size_request(150, 30)
    anime_info_h_box4.pack_start(@anime_add_btn, expand: true)

    @anime_edit_button = Gtk::Button.new(label: I18n.t('menu.modify'))
    @anime_edit_button.set_size_request(150, 30)
    anime_info_h_box4.pack_start(@anime_edit_button, expand: true)

    @anime_remove_button = Gtk::Button.new(label: I18n.t('menu.remove'))
    @anime_remove_button.set_size_request(150, 30)
    anime_info_h_box4.pack_start(@anime_remove_button, expand: true)

    @anime_edit_button.sensitive = false
    @anime_remove_button.sensitive = false

    anime_list_v_box = Gtk::Box.new(:vertical)
    @anime_data_main_box.pack_start(anime_list_v_box)

    @anime_list_scroll = Gtk::ScrolledWindow.new
    @anime_list_scroll.set_size_request(500, 255)
    anime_list_v_box.pack_start(@anime_list_scroll)

    @anime_list = Gtk::ListBox.new
    @anime_list_scroll.add(@anime_list)

    anime_list_h_box = Gtk::Box.new(:horizontal)
    anime_list_v_box.pack_start(anime_list_h_box)

    @anime_clear_btn = Gtk::Button.new(label: I18n.t('menu.clear'))
    @anime_clear_btn.set_size_request(165, 30)
    anime_list_h_box.pack_start(@anime_clear_btn)

    @anime_search_btn = Gtk::Button.new(label: I18n.t('menu.search'))
    @anime_search_btn.set_size_request(165, 30)
    anime_list_h_box.pack_start(@anime_search_btn)

    @anime_list_btn = Gtk::Button.new(label: I18n.t('content.get_from_list'))
    @anime_list_btn.set_size_request(165, 30)
    anime_list_h_box.pack_start(@anime_list_btn)

    load_anime_frame_data
    set_anime_connect
  end

  # アニメのUIのウィゼットの設定
  def set_anime_connect
    # アニメの制作日付の入力チェック
    @anime_date_entry.signal_connect('focus-out-event') do |widget, event|
      date_text = widget.text

      # 1990-01-01の形式で入力されているかチェック
      widget.text = '' unless date_text.match?(/^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1])$/)
    end

    # アニメのエピソードの入力チェック
    @anime_episode_entry.signal_connect('changed') do |widget|
      current_text = widget.text

      # 数字のみで入力されているかチェック
      widget.text = current_text.gsub(/\D/, '') unless current_text.match?(/\A\d+\z/)
    end

    # アニメの制作会社の選択ボタンのクリックイベント
    @company_manage_btn.signal_connect('clicked') do
      studio_selector = CompanySelector.new(@window, @company_type, @company_ides)

      # 戻り値を配列に格納
      @company_ides = company_selector(studio_selector)
    end

    # アニメの画像の編集ボタンのクリックイベント
    @anime_image_btn.signal_connect('clicked') do
      image_edit_window
    end

    # アニメのリストのダブルクリックイベント
    @anime_list.signal_connect('button_press_event') do |widget, event|
      if event.type == Gdk::EventType::BUTTON2_PRESS
        selected_row = widget.selected_row

        if selected_row
          @content_id = selected_row.name.to_i
          data_list_clicked
        end
      end
    end

    # アニメのクリアボタンのクリックイベント
    @anime_clear_btn.signal_connect('clicked') do
      @content_id = nil
      clear_anime_data
      clear_common_data
    end

    # アニメの検索ボタンのクリックイベント
    @anime_search_btn.signal_connect('clicked') do
      content_search_btn_clicked
    end

    # アニメリストからの追加ボタンのクリックイベント
    @anime_list_btn.signal_connect('clicked') do
      data_list_btn_clicked
    end

    # アニメの追加ボタンのクリックイベント
    @anime_add_btn.signal_connect('clicked') do
      data_add_btn_clicked
    end

    # アニメの更新ボタンのクリックイベント
    @anime_edit_button.signal_connect('clicked') do
      data_edit_btn_clicked
    end

    # アニメの削除ボタンのクリックイベント
    @anime_remove_button.signal_connect('clicked') do
      remove_btn_clicked
    end
  end

  # アニメのフレイムデータの読み込み
  def load_anime_frame_data
    # storage：ストレージ
    # media：メディア
    # rip：リップ
    # ratio：比率
    common = %w[storage media rip ratio]

    # 種別に応じたデータを読み込む
    common.each do |item|
      result = @common_controller.get_type_menu(item)

      if result.is_a?(String)
        dialog_message(@window, :error, :db_error, result)
        next
      end

      text_renderer = Gtk::CellRendererText.new
      combo_model = Gtk::ListStore.new(String, Integer)

      case item
      when 'storage'
        primary = combo_model.append
        primary[0] = I18n.t('content.storage')
        primary[1] = 0
      when 'media'
        primary = combo_model.append
        primary[0] = I18n.t('content.media')
        primary[1] = 0
      when 'rip'
        primary = combo_model.append
        primary[0] = I18n.t('content.rip')
        primary[1] = 0
      end

      if item == 'ratio'
        result.each do |item2|
          ratio_check = Gtk::CheckButton.new
          ratio_check.label = item2.name
          ratio_check.name = item2.id.to_s
          @ratio_box.pack_start(ratio_check)
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
      end
    end
  end

  # アニメのリストの読み込み
  def load_anime_data
    anime = @anime_controller.get_anime_list(@group_id, @keyword)

    if anime.is_a?(String)
      dialog_message(@window, :error, :write_error, anime)
      return
    end

    clear_list_box(@anime_list)

    anime.each do |item|
      row = Gtk::ListBoxRow.new
      row.add(Gtk::Label.new(item.name))
      row.name = item.id.to_s
      row.halign = Gtk::Align::START

      @anime_list.add(row)
    end

    @anime_list_scroll.vadjustment.value = 0.0
    @anime_list.show_all
  end

  # 一つのアニメの情報の読み込み
  def load_one_anime_data
    anime = @anime_controller.get_anime_by_id(@content_id)

    if anime.is_a?(String)
      dialog_message(@window, :error, :db_error, anime)
      return
    end

    @anime_title_entry.text = anime.name

    # アニメ情報をコンボボックスと一致するように設定する
    combo_boxes = [@storage_combo, @media_combo, @rip_combo]
    items = [anime.storage, anime.media, anime.rip]

    array = combo_boxes.zip(items).map do |combo, item|
      { 'combo_box' => combo, 'active' => item }
    end

    combo_selector(array)

    # アニメの比率情報を一致するようにラジオボタンをチェックする
    ratio = anime.ratio.split(',').map(&:to_i)

    @ratio_box.children.each do |child|
      child.set_active(false)

      ratio.each do |item|
        child.set_active(true) if child.name == item.to_s
      end
    end

    # エントリーにアニメの情報を入れる
    @anime_date_entry.text = anime.created_date
    @anime_episode_entry.text = anime.episode.to_s

    # アニメの制作会社情報を配列に格納する
    studio = anime.studio.split(',').map(&:to_i)
    @company_ides = load_company_data(studio)

    # アニメのイメージは更新がされてないから、nilとする
    # 画像情報はimage_editのダイアログで読み込む
    @img_file = nil
    @img_del = 'N'

    # アニメの更新ボタンと削除ボタンの有効化
    @anime_edit_button.sensitive = true
    @anime_remove_button.sensitive = true
  end

  # 書籍UIの設定
  def book_data
    @book_data_main_box = Gtk::Box.new(:horizontal)
    @book_data_main_box.set_margin_start(50)
    @book_data_main_box.set_margin_end(50)
    @main_v_box.pack_start(@book_data_main_box, expand: true)

    book_info_v_box = Gtk::Box.new(:vertical)
    @book_data_main_box.pack_start(book_info_v_box, expand: true)

    @book_title_entry = Gtk::Entry.new
    @book_title_entry.set_size_request(450, 50)
    @book_title_entry.placeholder_text = I18n.t('content.name_placeholder')
    book_info_v_box.pack_start(@book_title_entry)

    book_info_h_box1 = Gtk::Box.new(:horizontal)
    book_info_v_box.pack_start(book_info_h_box1, expand: true)

    @book_date_entry = Gtk::Entry.new
    @book_date_entry.set_size_request(450, 35)
    @book_date_entry.placeholder_text = I18n.t('content.date_placeholder')
    book_info_h_box1.pack_start(@book_date_entry)

    book_info_h_box2 = Gtk::Box.new(:horizontal)
    book_info_v_box.pack_start(book_info_h_box2, expand: true)

    @publisher_manage_btn = Gtk::Button.new(label: I18n.t('content.publisher_management'))
    @publisher_manage_btn.set_size_request(225, 40)
    book_info_h_box2.pack_start(@publisher_manage_btn)

    @book_image_btn = Gtk::Button.new(label: I18n.t('content.image_management'))
    @book_image_btn.set_size_request(225, 40)
    book_info_h_box2.pack_start(@book_image_btn)

    book_info_h_box3 = Gtk::Box.new(:horizontal)
    book_info_v_box.pack_start(book_info_h_box3, expand: true)

    @book_add_btn = Gtk::Button.new(label: I18n.t('menu.add'))
    @book_add_btn.set_size_request(150, 30)
    book_info_h_box3.pack_start(@book_add_btn)

    @book_edit_button = Gtk::Button.new(label: I18n.t('menu.modify'))
    @book_edit_button.set_size_request(150, 30)
    book_info_h_box3.pack_start(@book_edit_button)

    @book_remove_button = Gtk::Button.new(label: I18n.t('menu.remove'))
    @book_remove_button.set_size_request(150, 30)
    book_info_h_box3.pack_start(@book_remove_button)

    @book_edit_button.sensitive = false
    @book_remove_button.sensitive = false

    book_list_v_box = Gtk::Box.new(:vertical)
    @book_data_main_box.pack_start(book_list_v_box, expand: true)

    @book_list_scroll = Gtk::ScrolledWindow.new
    @book_list_scroll.set_size_request(500, 255)
    book_list_v_box.pack_start(@book_list_scroll)

    @book_list = Gtk::ListBox.new
    @book_list_scroll.add(@book_list)

    book_list_h_box = Gtk::Box.new(:horizontal)
    book_list_v_box.pack_start(book_list_h_box)

    @book_clear_btn = Gtk::Button.new(label: I18n.t('menu.clear'))
    @book_clear_btn.set_size_request(165, 30)
    book_list_h_box.pack_start(@book_clear_btn)

    @book_search_btn = Gtk::Button.new(label: I18n.t('menu.search'))
    @book_search_btn.set_size_request(165, 30)
    book_list_h_box.pack_start(@book_search_btn)

    @book_list_btn = Gtk::Button.new(label: I18n.t('content.get_from_list'))
    @book_list_btn.set_size_request(165, 30)
    book_list_h_box.pack_start(@book_list_btn)

    set_book_connect
  end

  # 書籍UIのウィゼットの設定
  def set_book_connect
    # 書籍の出版日付の入力チェック
    @book_date_entry.signal_connect('focus-out-event') do |widget, event|
      date_text = widget.text

      # 1990-01-01の形式で入力されているかチェック
      widget.text = '' unless date_text.match?(/^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1])$/)
    end

    # 書籍の出版社の管理ボタンのクリックイベント
    @publisher_manage_btn.signal_connect('clicked') do
      publisher_selector = CompanySelector.new(@window, @company_type, @company_ides)

      # 出版社の情報を配列に格納する
      @company_ides = company_selector(publisher_selector)
    end

    # 書籍のイメージの管理ボタンのクリックイベント
    @book_image_btn.signal_connect('clicked') do
      image_edit_window
    end

    # 書籍のリストのダブルクリックイベント
    @book_list.signal_connect('button_press_event') do |widget, event|
      if event.type == Gdk::EventType::BUTTON2_PRESS
        selected_row = widget.selected_row

        if selected_row
          @content_id = selected_row.name.to_i
          data_list_clicked
        end
      end
    end

    # 書籍のリストのクリアボタンのクリックイベント
    @book_clear_btn.signal_connect('clicked') do
      @content_id = nil
      clear_book_data
      clear_common_data
    end

    # 書籍のリストの検索ボタンのクリックイベント
    @book_search_btn.signal_connect('clicked') do
      content_search_btn_clicked
    end

    # 書籍リストからの追加ボタンのクリックイベント
    @book_list_btn.signal_connect('clicked') do
      data_list_btn_clicked
    end

    # 書籍の追加ボタンのクリックイベント
    @book_add_btn.signal_connect('clicked') do
      data_add_btn_clicked
    end

    # 書籍の更新ボタンのクリックイベント
    @book_edit_button.signal_connect('clicked') do
      data_edit_btn_clicked
    end

    # 書籍の削除ボタンのクリックイベント
    @book_remove_button.signal_connect('clicked') do
      remove_btn_clicked
    end
  end

  # 書籍のリストの読み込み
  def load_book_data
    type = @selected_group_original_combo.active_iter[1]
    book = @book_controller.get_book_list(type, @group_id, @keyword)

    if book.is_a?(String)
      dialog_message(@window, :error, :db_error, book)
      return
    end

    clear_list_box(@book_list)

    book.each do |item|
      row = Gtk::ListBoxRow.new
      row.add(Gtk::Label.new(item.name))
      row.name = item.id.to_s
      row.halign = Gtk::Align::START

      @book_list.add(row)
    end

    @book_list_scroll.vadjustment.value = 0.0
    @book_list.show_all
  end

  # 一つの書籍の情報の読み込み
  def load_one_book_data
    book = @book_controller.get_book_by_id(@content_id)

    if book.is_a?(String)
      dialog_message(@window, :error, :db_error, book)
      return
    end

    # 書籍の情報をエントリーに入れる
    @book_title_entry.text = book.name
    @book_date_entry.text = book.created_date

    # 書籍の出版社情報を配列に格納する
    publisher = book.publisher.split(',').map(&:to_i)
    @company_ides = load_company_data(publisher)

    # 書籍のイメージは更新がされてないから、nilとする
    @img_file = nil
    @img_del = 'N'

    # 書籍の更新ボタンと削除ボタンの有効化
    @book_edit_button.sensitive = true
    @book_remove_button.sensitive = true
  end

  # グループUIの設定
  def data_group_frame
    @group_main_box = Gtk::Box.new(:horizontal)
    @main_v_box.pack_start(@group_main_box)

    @group_list_scroll = Gtk::ScrolledWindow.new
    @group_list_scroll.set_size_request(1000, 200)
    @group_main_box.pack_start(@group_list_scroll, expand: true)

    @group_list = Gtk::ListBox.new
    @group_list_scroll.add(@group_list)

    set_group_connect
  end

  # グループUIのウィゼットの設定
  def set_group_connect
    # グループのリストのダブルクリックイベント
    @group_list.signal_connect('button_press_event') do |widget, event|
      if event.type == Gdk::EventType::BUTTON2_PRESS
        selected_row = widget.selected_row

        if selected_row
          item = selected_row.name.to_i

          group = @group_controller.get_one_group(item)

          if group.is_a?(String)
            dialog_message(@window, :error, :db_error, group)
            next
          end

          # アニメと書籍のリストをクリアする
          clear_list_box(@anime_list)
          clear_list_box(@book_list)

          # フレイムを初期化する
          initialize_window
          clear_common_data

          group.name = truncate_string(group.name, 'manage')

          @group_id = group.id
          @selected_group_label.text = "#{I18n.t('content.group_name')}#{group.name}　" +
                                       "（#{I18n.t('menu.original')}：#{group.original_name}）"
          @selected_group_original_combo.active = 0
          @selected_group_original_combo.sensitive = true
          @no_data_label.text = I18n.t('content.select_original')
        end
      end
    end
  end

  # 下のボタンのUIの設定
  def bottom_btn_frame
    @bottom_btn_box = Gtk::Box.new(:horizontal)
    @main_v_box.pack_start(@bottom_btn_box, padding: 10)

    @modify_btn = Gtk::Button.new(label: I18n.t('content.modify_group'))
    @modify_btn.set_size_request(270, 50)
    @bottom_btn_box.pack_start(@modify_btn, expand: true)

    @back_btn = Gtk::Button.new(label: I18n.t('menu.back'))
    @back_btn.set_size_request(270, 50)
    @bottom_btn_box.pack_start(@back_btn, expand: true)
  end

  # 原作情報の読み込み
  def load_original_combo
    text_renderer = Gtk::CellRendererText.new

    @selected_group_original_combo.clear

    original = @common_controller.get_type_menu('original')

    if original.is_a?(String)
      dialog_message(@window, :error, :db_error, e.message)
      return
    end

    # 読み込んだ情報をコンボボックスに入れる
    original_model = Gtk::ListStore.new(String, Integer)

    primary = original_model.append
    primary[0] = I18n.t('menu.original')
    primary[1] = 0

    original.each do |item|
      iter = original_model.append
      iter[0] = item.name
      iter[1] = item.id
    end

    @selected_group_original_combo.model = original_model
    @selected_group_original_combo.pack_start(text_renderer, true)
    @selected_group_original_combo.set_attributes(text_renderer, text: 0)
    @selected_group_original_combo.active = 0
  end

  # ウィゼットの設定
  def set_signal_connect
    # コンテンツの変更ボタンのクリックイベント
    @content_edit.signal_connect('clicked') do
      content = {}

      content['id'] = @id
      content['name'] = @content_title.text

      result = @content_controller.modify_content(Content.new(content))

      if result.is_a?(String)
        dialog_message(@window, :error, :modify_error, result)
        next
      end

      if result
        dialog_message(@window, :info, :modify_success)
      else
        dialog_message(@window, :warning, :duplicate_data)
      end
    end

    # コンテンツの削除ボタンのクリックイベント
    @content_remove.signal_connect('clicked') do
      con = confirm_dialog(:remove_confirm, @window)
      res = con.run

      if res == Gtk::ResponseType::YES
        result = @content_controller.remove_content(@id)

        if result.is_a?(String)
          dialog_message(@window, :error, :remove_error, result)
          next
        end

        dialog_message(@window, :info, :remove_success)

        layout_changer = LayoutChanger.new

        layout_changer.change_layout(@stack, 1)
      end

      con.destroy
    end

    # グループの変更ボタンのクリックイベント
    @modify_btn.signal_connect('clicked') do
      group_selector = GroupSelector.new(@window, @id)

      # マップに設定された情報をもとにグループを読み込む
      group_selector.signal_connect('response') do |widget, response|
        load_group_list if response == Gtk::ResponseType::OK
      end
    end

    # 戻るボタンのクリックイベント
    @back_btn.signal_connect('clicked') do
      layout_changer = LayoutChanger.new

      # HomeIndexへと切り替える
      layout_changer.change_layout(@stack, 1)
    end

    # 原作コンボボックスの変更イベント
    @selected_group_original_combo.signal_connect('changed') do |combo|
      @keyword = nil

      case combo.active_iter[0]
      when I18n.t('original.anime')
        frame_changer('studio', @anime, false, true, false)
        load_anime_data
      when I18n.t('original.manga'), I18n.t('original.novel')
        frame_changer('publisher', @book, false, false, true)
        load_book_data
      when I18n.t('menu.original')
        @no_data_label.text = I18n.t('content.select_original')
        frame_changer(nil, nil, true, false, false)
      else
        @no_data_label.text = I18n.t('content.no_support')
        frame_changer(nil, nil, true, false, false)
      end

      @content_id = nil
      @img_file = nil
      @img_del = 'N'
      @img_file_name = nil

      clear_anime_data
      clear_book_data
      clear_common_data
    end
  end

  # 原作が選択されてないときのUIの初期化
  def initialize_no_data
    @no_data_main_box.visible = true
  end

  # アニメUIの初期化
  def initialize_anime_data
    clear_anime_data
    @anime_data_main_box.visible = false
  end

  # アニメウィゼットの初期化
  def clear_anime_data
    @anime_title_entry.text = ''
    @anime_date_entry.text = ''
    @anime_episode_entry.text = ''

    @storage_combo.active = 0
    @media_combo.active = 0
    @rip_combo.active = 0

    @anime_edit_button.sensitive = false
    @anime_remove_button.sensitive = false

    @ratio_box.children.each do |item|
      item.set_active(false)
    end
  end

  # 書籍UIの初期化
  def initialize_book_data
    clear_book_data
    @book_data_main_box.visible = false
  end

  # 書籍ウィゼットの初期化
  def clear_book_data
    @book_title_entry.text = ''
    @book_date_entry.text = ''

    @book_edit_button.sensitive = false
    @book_remove_button.sensitive = false
  end

  # 共通ウィゼットの初期化
  def clear_common_data
    @img_file = nil
    @img_del = 'N'
    @img_file_name = nil

    @company_ides = []
  end

  # フレイムの変更
  def frame_changer(company, content, no_data, anime, book)
    @company_type = company
    @content_type = content

    @no_data_main_box.visible = no_data
    @anime_data_main_box.visible = anime
    @book_data_main_box.visible = book
  end

  # イメージの編集のウィンドウの作成
  def image_edit_window
    image_edit = ImageEdit.new(@window, @content_type, @content_id, @img_file, @img_del)

    image_edit.signal_connect('response') do |widget, response|
      if response == Gtk::ResponseType::OK
        @img_file = image_edit.img
        @img_del = image_edit.img_del
        @img_file_name = image_edit.file_name if @img_file_name.nil? ||
                                                 (!@img_file_name.nil? && @img_file_name != image_edit.file_name)
      end
    end
  end

  # リストのダブルクリックの時、分岐する
  def data_list_clicked
    if @content_type == @anime
      load_one_anime_data
    elsif @content_type == @book
      load_one_book_data
    end
  end

  # グループリストの読み込み
  def load_group_list
    clear_list_box(@group_list)

    group = @group_controller.get_selected_group_list(@id)

    if group.is_a?(String)
      dialog_message(@window, :error, :db_error, group)
      return
    end

    group.each do |item|
      row = Gtk::ListBoxRow.new
      row.add(Gtk::Label.new(item.name))
      row.name = item.id.to_s

      @group_list.add(row)
    end

    @group_list_scroll.vadjustment.value = 0.0
    @group_list.show_all
  end

  # 会社データを配列に格納して返す
  def load_company_data(companies)
    ides = []

    companies.each do |company|
      ides.push(company)
    end

    ides
  end

  # 各情報を検証して、エラーがあればメッセージを表示する
  # 成功したら、検証した情報を返す
  def data_validate

    result = if @content_type == @anime
               anime_validation
             elsif @content_type == @book
               book_validation
             end

    unless result.is_a?(Hash)
      dialog_message(@window, :warning, result)
      return nil
    end

    result
  end

  # 検索ボタンのクリックの時、分岐する
  def content_search_btn_clicked
    content_search = ContentSearch.new(@window)

    content_search.signal_connect('response') do |widget, response|
      if response == Gtk::ResponseType::OK
        @keyword = content_search.keyword

        if @content_type == @anime
          load_anime_data
        elsif @content_type == @book
          load_book_data
        end
      end
    end
  end

  # 情報を追加ボタンを押すとき、分岐する
  def data_add_btn_clicked
    @keyword = nil

    if @content_type == @anime
      anime = data_validate

      return if anime.nil?

      # アニメ情報、content_type、group_id、イメージ情報をまとめる
      param = {
        anime: Anime.new(anime),
        content_type: @content_type,
        group_id: @group_id,
        img_file_name: @img_file_name
      }

      result = @anime_controller.add_anime(param)

      if result.is_a?(String)
        dialog_message(@window, :error, :write_error, result)
        return
      end

      dialog_message(@window, :info, :write_success)

      clear_anime_data
      clear_common_data
      load_anime_data

    elsif @content_type == @book
      book = data_validate

      return if book.nil?

      # 書籍情報、content_type、group_id、イメージ情報をまとめる
      param = {
        book: Book.new(book),
        content_type: @content_type,
        group_id: @group_id,
        img_file_name: @img_file_name
      }

      result = @book_controller.add_book(param)

      if result.is_a?(String)
        dialog_message(@window, :error, :write_error, result)
        return
      end

      dialog_message(@window, :info, :write_success)

      clear_book_data
      clear_common_data
      load_book_data
    end
  end

  # 更新ボタンのクリックの時、分岐する
  def data_edit_btn_clicked
    img = { "img_file_name": @img_file_name,
            "content_type": @content_type,
            "content_id": @content_id,
            "img_del": @img_del }

    result = if @content_type == @anime
               anime = data_validate

               return if anime.nil?

               anime['id'] = @content_id
               @anime_controller.modify_anime(Anime.new(anime), img)
             elsif @content_type == @book
               book = data_validate

               return if book.nil?

               book['id'] = @content_id
               @book_controller.modify_book(Book.new(book), img)
             end

    if result.is_a?(String)
      dialog_message(@window, :error, :modify_error, result)
      return
    end

    dialog_message(@window, :warning, :duplicate_data) unless result
    dialog_message(@window, :info, :modify_success) if result

    @img_file = nil
    @img_del = 'N'
    @img_file_name = nil

    load_anime_data if @content_type == @anime
    load_book_data if @content_type == @book
  end

  # 削除ボタンのクリックの時、分岐する
  def remove_btn_clicked
    con = confirm_dialog(:remove_confirm, @window)
    res = con.run

    if res == Gtk::ResponseType::YES
      file = {}

      file['refer_tb'] = @content_type
      file['refer_id'] = @content_id

      result = if @content_type == @anime
                 @anime_controller.remove_anime(@content_id, Files.new(file))
               elsif @content_type == @book
                 @book_controller.remove_book(@content_id, Files.new(file))
               end

      if result.is_a?(String)
        dialog_message(@window, :error, :remove_error, result)
        return
      end

      dialog_message(@window, :info, :remove_success)

      if @content_type == @anime
        clear_anime_data
        load_anime_data
      elsif @content_type == @book
        clear_book_data
        load_book_data
      end
      clear_common_data
    end

    con.destroy
  end

  # リストから追加ボタンのクリックの時、分岐する
  def data_list_btn_clicked
    original = @selected_group_original_combo.active_iter[1]

    data_selector = DataSelector.new(@window, @content_type, original, @group_id)

    data_selector.signal_connect('response') do |widget, response|
      if response == Gtk::ResponseType::OK
        if @content_type == @anime
          load_anime_data
        elsif @content_type == @book
          load_book_data
        end
      end
    end
  end
end
