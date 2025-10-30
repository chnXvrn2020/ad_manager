# frozen_string_literal: true

require_relative 'view_image'
require_relative 'view_search'

class ViewIndex
  attr_reader :frame

  # 初期設定
  def initialize(window, stack)
    @window = window
    @stack = stack
    @frame = Gtk::Frame.new
    @content_controller = ContentController.new
    @group_controller = GroupController.new
    @anime_controller = AnimeController.new
    @book_controller = BookController.new
    @company_controller = CompanyController.new
    @common_controller = CommonController.new
    @file_controller = FileController.new
    @content_id = 0
    @group_id = 0
    @id = 0
    @type_id = 0
    @book_count = 0
    @group_keyword = nil
    @keyword = nil
    @type = nil
    @img_path = img_path
    @anime_stop = false
    @img = nil
    @no_image = no_image_path

    set_ui
    set_signal_connect
  end

  # UIの初期化
  def initialize_ui(data)
    @group_keyword = nil
    @keyword = nil
    @group_id = 0
    @id = 0
    @type = nil
    @img = nil

    @original_combo.sensitive = false
    @original_combo.active = 0

    @original_label.text = I18n.t('content_view.original')

    clear_list_box(@data_list)

    initialize_frame

    # 他のレイアウトから引数として渡されたデータの処理
    if data.is_a?(Integer)
      @content_id = data
      load_content_data(data)
      load_group_list
    else
      load_initial_data(data)

      @status_check_btn.sensitive = true
    end

  end

  # 初期ウィンドウの設定
  def initialize_window
    initialize_frame
  end

  private

  # UIの設定
  def set_ui
    @main_v_box = Gtk::Box.new(:vertical)
    @main_v_box.set_margin_start(30)
    @main_v_box.set_margin_end(30)
    @main_v_box.set_margin_top(20)
    @main_v_box.set_margin_bottom(20)

    @frame.add(@main_v_box)

    title_v_box = Gtk::Box.new(:vertical)
    @main_v_box.pack_start(title_v_box, padding: 5)

    title_h_box = Gtk::Box.new(:horizontal, 10)
    title_h_box.set_margin_start(50)
    title_h_box.set_margin_end(50)
    title_v_box.pack_start(title_h_box)

    @title_entry = Gtk::Entry.new
    @title_entry.set_size_request(900, 30)
    @title_entry.editable = false
    @title_entry.set_alignment(0.5)
    title_h_box.pack_start(@title_entry)

    @original_label = Gtk::Label.new(I18n.t('content_view.original'))
    title_h_box.pack_start(@original_label)

    list_h_box = Gtk::Box.new(:horizontal)
    title_v_box.pack_start(list_h_box, padding: 10)

    @group_list_scroll = Gtk::ScrolledWindow.new
    @group_list_scroll.set_size_request(400, 300)
    list_h_box.pack_start(@group_list_scroll, expand: true)

    @group_list = Gtk::ListBox.new
    @group_list_scroll.add(@group_list)

    @data_list_scroll = Gtk::ScrolledWindow.new
    @data_list_scroll.set_size_request(400, 300)
    list_h_box.pack_start(@data_list_scroll, expand: true)

    @data_list = Gtk::ListBox.new
    @data_list_scroll.add(@data_list)

    list_v_box = Gtk::Box.new(:vertical, 30)
    list_h_box.pack_start(list_v_box, padding: 20)

    @original_combo = Gtk::ComboBoxText.new
    @original_combo.set_size_request(100, 30)
    list_v_box.pack_start(@original_combo)

    @search_btn = Gtk::Button.new(label: I18n.t('menu.search'))
    @search_btn.set_size_request(100, 30)
    list_v_box.pack_start(@search_btn)

    @status_check_btn = Gtk::Button.new(label: I18n.t('view.status'))
    @status_check_btn.set_size_request(100, 30)
    list_v_box.pack_start(@status_check_btn)

    set_combo_box

    no_data
    anime_data
    book_data
    bottom_btn_frame
  end

  # ウィゼットの設定
  def set_signal_connect
    # グループリストのダブルクリックイベント
    @group_list.signal_connect('button_press_event') do |widget, event|
      if event.type == Gdk::EventType::BUTTON2_PRESS
        selected_row = widget.selected_row

        if selected_row
          @group_id = selected_row.name.to_i

          load_group_data

          clear_list_box(@data_list)
          @original_combo.sensitive = true
          @original_combo.active = 0
        end
      end
    end

    # アニメ、書籍データのリストのダブルクリックイベント
    @data_list.signal_connect('button_press_event') do |widget, event|
      if event.type == Gdk::EventType::BUTTON2_PRESS
        selected_row = widget.selected_row

        if selected_row
          @id = selected_row.name.to_i
          if @type == 'tb_anime'
            @status_check_btn.sensitive = true
            load_anime_data
          elsif @type == 'tb_book'
            load_book_data
          end
        end
      end
    end

    # 原作コンボボックスの選択イベント
    @original_combo.signal_connect('changed') do |widget|
      @keyword = nil

      if widget.active == 0
        clear_list_box(@data_list)
        @status_check_btn.sensitive = false
      else
        common = load_data(widget.active_iter[1])
        db_data(common)

        status_check_btn(widget.active_iter[1])
      end
    end

    # 検索ボタンのクリックイベント
    @search_btn.signal_connect('clicked') do
      view_search = ViewSearch.new(@window, @group_id)

      view_search.signal_connect('response') do |widget, response|
        if response == Gtk::ResponseType::OK
          radio = view_search.radio_active

          # ダイアログから渡された引数を元にデータを読み込む
          if radio == I18n.t('view.group')
            @group_keyword = view_search.keyword
            load_group_list
          elsif radio == I18n.t('view.data')
            @keyword = view_search.keyword
            common = load_data(@type_id)
            db_data(common)
          end
        end
      end

    end

    # 現状態のチェックボタンのクリックイベント
    @status_check_btn.signal_connect('clicked') do
      if @type == 'tb_anime'
        check_anime_status
      else
        check_book_status
      end
    end

    # 戻るボタンのクリックイベント
    @back_btn.signal_connect('clicked') do
      layout_changer = LayoutChanger.new

      # HomeIndexへと切り替える
      layout_changer.change_layout(@stack, 0)
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

  # 何も選択されてない時のUI
  def no_data
    @no_data_main_box = Gtk::Box.new(:vertical)
    @no_data_main_box.set_size_request(600, 300)
    @main_v_box.pack_start(@no_data_main_box, expand: true)

    @no_data_label = Gtk::Label.new(I18n.t('view.no_selected'))
    @no_data_main_box.pack_start(@no_data_label, expand: true)

    @status_check_btn.sensitive = false
  end

  # アニメが選択された時のUI
  def anime_data
    @anime_main_box = Gtk::Box.new(:horizontal)
    @main_v_box.pack_start(@anime_main_box, expand: true)

    @anime_img = Gtk::Image.new
    @anime_img.set_size_request(250, 320)

    @anime_img_event_box = Gtk::EventBox.new
    @anime_img_event_box.add(@anime_img)
    @anime_main_box.pack_start(@anime_img_event_box)

    info_v_box = Gtk::Box.new(:vertical)
    @anime_main_box.pack_start(info_v_box)

    title_h_box = Gtk::Box.new(:horizontal)
    info_v_box.pack_start(title_h_box, expand: true)

    @anime_title = Gtk::Entry.new
    @anime_title.set_size_request(700, 40)
    @anime_title.editable = false
    @anime_title.set_alignment(0.5)
    title_h_box.pack_start(@anime_title)

    @status_label = Gtk::Label.new('')
    title_h_box.pack_start(@status_label, expand: true)

    info_h_box1 = Gtk::Box.new(:horizontal)
    info_v_box.pack_start(info_h_box1, expand: true)

    storage_label = Gtk::Label.new(I18n.t('view.storage'))
    info_h_box1.pack_start(storage_label)

    @storage_entry = Gtk::Entry.new
    @storage_entry.set_size_request(200, 35)
    @storage_entry.editable = false
    info_h_box1.pack_start(@storage_entry, expand: true)

    media_label = Gtk::Label.new(I18n.t('view.media'))
    info_h_box1.pack_start(media_label)

    @media_entry = Gtk::Entry.new
    @media_entry.set_size_request(200, 35)
    @media_entry.editable = false
    info_h_box1.pack_start(@media_entry, expand: true)

    rip_label = Gtk::Label.new(I18n.t('view.rip'))
    info_h_box1.pack_start(rip_label)

    @rip_entry = Gtk::Entry.new
    @rip_entry.set_size_request(200, 35)
    @rip_entry.editable = false
    info_h_box1.pack_start(@rip_entry, expand: true)

    info_h_box2 = Gtk::Box.new(:horizontal)
    info_v_box.pack_start(info_h_box2, expand: true)

    studio_label = Gtk::Label.new(I18n.t('view.studio'))
    info_h_box2.pack_start(studio_label)

    @studio_entry = Gtk::Entry.new
    @studio_entry.set_size_request(200, 35)
    @studio_entry.editable = false
    info_h_box2.pack_start(@studio_entry, expand: true)

    created_date_label = Gtk::Label.new(I18n.t('view.created_date'))
    info_h_box2.pack_start(created_date_label)

    @anime_created = Gtk::Entry.new
    @anime_created.set_size_request(200, 35)
    @anime_created.editable = false
    info_h_box2.pack_start(@anime_created, expand: true)

    ratio_label = Gtk::Label.new(I18n.t('view.ratio'))
    info_h_box2.pack_start(ratio_label)

    @ratio_entry = Gtk::Entry.new
    @ratio_entry.set_size_request(200, 35)
    @ratio_entry.editable = false
    info_h_box2.pack_start(@ratio_entry, expand: true)

    info_h_box3 = Gtk::Box.new(:horizontal)
    info_v_box.pack_start(info_h_box3, expand: true)

    current_label = Gtk::Label.new(I18n.t('view.current_episode'))
    info_h_box3.pack_start(current_label)

    @anime_current_entry = Gtk::Entry.new
    @anime_current_entry.set_size_request(200, 35)
    @anime_current_entry.editable = false
    info_h_box3.pack_start(@anime_current_entry, expand: true)

    episode_label = Gtk::Label.new(I18n.t('view.episode'))
    info_h_box3.pack_start(episode_label)

    @anime_episode_entry = Gtk::Entry.new
    @anime_episode_entry.set_size_request(200, 35)
    @anime_episode_entry.editable = false
    info_h_box3.pack_start(@anime_episode_entry, expand: true)

    complete_label = Gtk::Label.new(I18n.t('view.completed'))
    info_h_box3.pack_start(complete_label)

    @anime_complete_entry = Gtk::Entry.new
    @anime_complete_entry.set_size_request(200, 35)
    @anime_complete_entry.editable = false
    info_h_box3.pack_start(@anime_complete_entry, expand: true)

    btn_box = Gtk::Box.new(:horizontal)
    info_v_box.pack_start(btn_box, expand: true)

    @anime_start_btn = Gtk::Button.new(label: I18n.t('view.start_watching'))
    @anime_start_btn.set_size_request(180, 50)
    btn_box.pack_start(@anime_start_btn, expand: true)

    @anime_stop_btn = Gtk::Button.new(label: I18n.t('view.start_watching'))
    @anime_stop_btn.set_size_request(180, 50)
    btn_box.pack_start(@anime_stop_btn, expand: true)

    @anime_save_btn = Gtk::Button.new(label: I18n.t('view.save_watching'))
    @anime_save_btn.set_size_request(180, 50)
    btn_box.pack_start(@anime_save_btn, expand: true)

    @anime_complete_btn = Gtk::Button.new(label:I18n.t('view.completed'))
    @anime_complete_btn.set_size_request(180, 50)
    btn_box.pack_start(@anime_complete_btn, expand: true)

    @anime_start_btn.sensitive = false
    @anime_stop_btn.sensitive = false
    @anime_save_btn.sensitive = false
    @anime_complete_btn.sensitive = false

    set_anime_connect
  end

  # アニメUIのウィゼットの設定
  def set_anime_connect

    # イメージのダブルクリックイベント
    @anime_img_event_box.signal_connect('button_press_event') do |widget, event|
      if event.type == Gdk::EventType::BUTTON2_PRESS
        next if @img.nil?

        ViewImage.new(@window, @img)
      end
    end

    # 開始ボタンのクリックイベント
    @anime_start_btn.signal_connect('clicked') do
      con = confirm_dialog(:anime_start, @window)
      res = con.run

      if res == Gtk::ResponseType::YES

        status = @anime_controller.start_watching_anime(@id)

        if status.is_a?(String)
          dialog_message(@window, :error, :modify_error, status)
          next
        end

        next if status.nil?

        @anime_current_entry.text = status.current_episode.to_s
        @status_label.text = status.status

        anime_status_btn(status.status, status)
        load_group_list
        load_anime_list
      end

      con.destroy
    end

    # 中止ボタンのクリックイベント
    @anime_stop_btn.signal_connect('clicked') do
      label = @anime_stop_btn.label

      # 場合によって再開にもなる
      type = if label == I18n.t('view.stop_watching')
               :anime_stop
             elsif label == I18n.t('view.restart_watching')
               :anime_restart
             end

      con = confirm_dialog(type, @window)
      res = con.run

      if res == Gtk::ResponseType::YES
        status = @anime_controller.modify_watching_anime(type, @id)

        if status.is_a?(String)
          dialog_message(@window, :error, :modify_error, status)
          next
        end

        next if status.nil?

        @status_label.text = status.status
        anime_status_btn(status.status, status)
        load_group_list
        load_anime_list
      end

      con.destroy
    end

    # セーブボタンのクリックイベント
    @anime_save_btn.signal_connect('clicked') do

        current_episode = @anime_current_entry.text.to_i
        result = @anime_controller.modify_anime_current_episode(current_episode, @id)

        dialog_message(@window, :info, :anime_save) if result.is_a?(TrueClass)
        dialog_message(@window, :error, :modify_error, result) if result.is_a?(String)

    end

    # コンプリボタンのクリックイベント
    @anime_complete_btn.signal_connect('clicked') do
      con = confirm_dialog(:anime_complete, @window)
      res = con.run

      completion_date = @anime_complete_entry.text.empty? ? nil : @anime_complete_entry.text

      if res == Gtk::ResponseType::YES
        status = @anime_controller.complete_watching_anime(@id, completion_date)

        if status.is_a?(String)
          dialog_message(@window, :error, :modify_error, status)
          next
        end

        next if status.nil?

        @status_label.text = status.status
        @anime_current_entry.text = status.current_episode.to_s

        anime_status_btn(status.status, status)
        load_group_list
        load_anime_list
      end

      con.destroy
    end

  end

  # 書籍が選択された時のUI
  def book_data
    @book_main_box = Gtk::Box.new(:horizontal)
    @main_v_box.pack_start(@book_main_box, expand: true)

    @book_img = Gtk::Image.new
    @book_img.set_size_request(250, 320)

    @book_img_event_box = Gtk::EventBox.new
    @book_img_event_box.add(@book_img)
    @book_main_box.pack_start(@book_img_event_box)

    info_v_box = Gtk::Box.new(:vertical)
    @book_main_box.pack_start(info_v_box)

    title_h_box = Gtk::Box.new(:horizontal, 25)
    info_v_box.pack_start(title_h_box, expand: true)

    @book_title = Gtk::Entry.new
    @book_title.set_size_request(700, 40)
    @book_title.editable = false
    @book_title.set_alignment(0.5)
    title_h_box.pack_start(@book_title)

    @book_status_label = Gtk::Label.new('')
    title_h_box.pack_start(@book_status_label, expand: true)

    info_h_box1 = Gtk::Box.new(:horizontal, 50)
    info_v_box.pack_start(info_h_box1, expand: true)

    publisher_label = Gtk::Label.new(I18n.t('view.publisher'))
    info_h_box1.pack_start(publisher_label)

    @publisher_entry = Gtk::Entry.new
    @publisher_entry.set_size_request(200, 35)
    @publisher_entry.editable = false
    info_h_box1.pack_start(@publisher_entry)

    release_date_label = Gtk::Label.new(I18n.t('view.release_date'))
    info_h_box1.pack_start(release_date_label)

    @release_date_entry = Gtk::Entry.new
    @release_date_entry.set_size_request(200, 35)
    @release_date_entry.editable = false
    info_h_box1.pack_start(@release_date_entry)

    info_h_box2 = Gtk::Box.new(:horizontal, 50)
    info_v_box.pack_start(info_h_box2, expand: true)

    completed_label = Gtk::Label.new(I18n.t('view.completed'))
    info_h_box2.pack_start(completed_label)

    @book_completed_entry = Gtk::Entry.new
    @book_completed_entry.set_size_request(200, 35)
    @book_completed_entry.editable = false
    info_h_box2.pack_start(@book_completed_entry)

    @book_complete_btn = Gtk::Button.new(label: I18n.t('view.completed'))
    @book_complete_btn.set_size_request(200, 35)
    info_h_box2.pack_start(@book_complete_btn)

    set_book_connect
  end

  # 書籍UIのウィゼットの設定
  def set_book_connect

    # イメージのダブルクリックイベント
    @book_img_event_box.signal_connect('button_press_event') do |widget, event|
      if event.type == Gdk::EventType::BUTTON2_PRESS
        next if @img.nil?

        ViewImage.new(@window, @img)
      end
    end

    # コンプリボタンのクリックイベント
    @book_complete_btn.signal_connect('clicked') do
      con = confirm_dialog(:anime_complete, @window)
      res = con.run

      completion_date = @book_completed_entry.text.empty? ? nil : @book_completed_entry.text

      if res == Gtk::ResponseType::YES
        status = @book_controller.complete_read_book(@id, completion_date)

        if status.is_a?(String)
          dialog_message(@window, :error, :modify_error, status)
          next
        end

        @book_status_label.text = status.status

        @book_complete_btn.sensitive = false

        load_group_list
        load_book_list
      end

      con.destroy
    end

  end

  # 下のボタンフレイムの設定
  def bottom_btn_frame
    @btn_h_box = Gtk::Box.new(:horizontal)
    @main_v_box.pack_start(@btn_h_box, expand: true)

    @back_btn = Gtk::Button.new(label: I18n.t('menu.back'))
    @back_btn.set_size_request(1100, 50)
    @btn_h_box.pack_start(@back_btn, expand: true)
  end

  # イメージがない時の代替イメージ
  def no_image(img_box)
    pixbuf = GdkPixbuf::Pixbuf.new(file: @no_image)

    set_image(pixbuf, img_box)
  end

  # イメージを変換する
  def convert_image(file)
    return if file.nil?

    GdkPixbuf::Pixbuf.new(file: "#{@img_path}#{file.file_name}")
  end

  # イメージをサイズに合わせて表示
  def set_image(pixbuf, img_box)
    return if pixbuf.nil?

    new_width = 250
    new_height = 320

    original_width = pixbuf.width
    original_height = pixbuf.height

    width_ratio = new_width.to_f / original_width
    height_ratio = new_height.to_f / original_height

    if width_ratio < height_ratio
      new_width = original_width * width_ratio
      new_height = original_height * width_ratio
    else
      new_width = original_width * height_ratio
      new_height = original_height * height_ratio
    end

    scaled_pixbuf = pixbuf.scale_simple( new_width.round, new_height.round, GdkPixbuf::InterpType::BILINEAR )

    img_box.set_from_pixbuf(scaled_pixbuf)
  end

  # 初期フレイムの設定
  def initialize_frame
    @no_data_main_box.visible = true
    @anime_main_box.visible = false
    @book_main_box.visible = false
  end

  # コンテンツデータの読み込み
  def load_content_data(data)
    result = @content_controller.get_one_content(data)

    if result.is_a?(String)
      dialog_message(@window, :error, :db_error, result)
      return
    end

    @title_entry.text = result.name
  end

  # グループリストの読み込み
  def load_group_list
    group = @group_controller.get_group_list_by_content_id(@content_id, @group_keyword)

    if group.is_a?(String)
      dialog_message(@window, :error, :db_error, group)
      return
    end

    clear_list_box(@group_list)

    group.each do |item|
      row = Gtk::ListBoxRow.new
      data = truncate_string(item.name, 'view')

      group_status_info = @group_controller.get_group_status_info(item.id)

      if group_status_info.is_a?(String)
        dialog_message(@window, :error, :db_error, group_status_info)
        next
      end

      # グループ名の後に状態を付与する
      status = group_status(group_status_info)

      row.add(Gtk::Label.new(data + status))
      row.name = item.id.to_s
      row.halign = Gtk::Align::START

      @group_list.add(row)
    end

    @group_list_scroll.vadjustment.value = 0.0
    @group_list.show_all
  end

  # メニューのデータの読み込み
  def load_data(type_id)
    @type_id = type_id
    result = @common_controller.get_one_common(type_id)

    if result.is_a?(String)
      dialog_message(@window, :error, :db_error, result)
      return nil
    end

    result
  end

  # アニメ、書籍の情報の読み込み
  def db_data(common)
    return clear_list_box(@data_list) if common.nil?

    case common.name
    when I18n.t('original.anime')
        load_anime_list
        @type = 'tb_anime'
    when I18n.t('original.manga'), I18n.t('original.novel')
        load_book_list
        @type = 'tb_book'
    else
        clear_list_box(@data_list)
    end
  end

  # アニメリストの読み込み
  def load_anime_list
    anime = @anime_controller.get_anime_list(@group_id, @keyword)

    if anime.is_a?(String)
      dialog_message(@window, :error, :write_error, anime)
      return
    end

    clear_list_box(@data_list)

    # 文字列が長い場合、省略する
    # タイトルの後に状態を付与する
    anime.each do |item|
      row = Gtk::ListBoxRow.new
      data = truncate_string(item.name, 'view')
      status = "　（#{item.status}）"

      row.add(Gtk::Label.new(data + status))
      row.name = item.id.to_s
      row.halign = Gtk::Align::START

      @data_list.add(row)
    end

    @data_list_scroll.vadjustment.value = 0.0
    @data_list.show_all
  end

  # 書籍リストの読み込み
  def load_book_list
    book = @book_controller.get_book_list(@type_id, @group_id, @keyword)

    if book.is_a?(String)
      dialog_message(@window, :error, :db_error, book)
      return
    end

    clear_list_box(@data_list)

    # 文字列が長い場合、省略する
    # タイトルの後に状態を付与する
    book.each do |item|
      row = Gtk::ListBoxRow.new
      data = truncate_string(item.name, 'view')
      status = "　（#{item.status}）"

      row.add(Gtk::Label.new(data + status))
      row.name = item.id.to_s
      row.halign = Gtk::Align::START

      @data_list.add(row)
    end

    @data_list_scroll.vadjustment.value = 0.0
    @data_list.show_all
  end

  # 一つのアニメ情報の読み込み
  def load_anime_data
    data = @anime_controller.get_anime_info_by_id(@type, @id)

    if data.is_a?(String)
      dialog_message(@window, :error, :db_error, data)
      return
    end

    anime = data['anime']
    img = data['file']
    status = data['status']

    img_result = convert_image(img)

    if img_result.nil?
      no_image(@anime_img)
    else
      set_image(img_result, @anime_img)
      @img = img
    end

    @anime_title.text = anime.name
    @storage_entry.text = load_common_data(anime.storage)
    @media_entry.text = load_common_data(anime.media)
    @rip_entry.text = load_common_data(anime.rip)

    studio_arg = []

    anime.studio.split(',').each do |item|
      studio_arg << load_company_data(item)
    end

    @studio_entry.text = studio_arg.join(', ')
    @anime_created.text = anime.created_date

    ratio_arg = []

    anime.ratio.split(',').each do |item|
      ratio_arg << load_common_data(item)
    end

    @ratio_entry.text = ratio_arg.join(', ')
    @anime_episode_entry.text = anime.episode.to_s

    # 状態ごとにボタンを切り替える
    if status.nil?
      @status_label.text = I18n.t('view.unwatched')
      @anime_current_entry.text = ''
      anime_status_btn(I18n.t('view.unwatched'))
    else
      @anime_current_entry.text = status.current_episode.to_s
      @status_label.text = status.status

      anime_status_btn(status.status, status)
    end

    frame_changer(false, true, false)
  end

  # 一つの書籍情報の読み込み
  def load_book_data
    data = @book_controller.get_book_info_by_id(@type, @id)

    if data.is_a?(String)
      dialog_message(@window, :error, :db_error, data)
      return
    end

    book = data['book']
    img = data['file']
    status = data['status']

    img_result = convert_image(img)

    if img_result.nil?
      no_image(@book_img)
    else
      set_image(img_result, @book_img)
      @img = img
    end

    @book_title.text = book.name

    publisher_arg = []

    book.publisher.split(',').each do |item|
      publisher_arg << load_company_data(item)
    end

    @publisher_entry.text = publisher_arg.join(', ')
    @release_date_entry.text = book.created_date

    # 状態ごとにボタンを切り替える
    if status.nil?
      @book_status_label.text = I18n.t('view.unwatched')
      @book_completed_entry.text = ''
      @book_completed_entry.editable = true
      @book_complete_btn.sensitive = true
    else
      @book_status_label.text = status.status
      @book_completed_entry.text = status.completion_date
      @book_completed_entry.editable = false
      @book_complete_btn.sensitive = false
    end

    frame_changer(false, false, true)
  end

  # フレイムの切り替え
  def frame_changer(no_data, anime, book)
    @no_data_main_box.visible = no_data
    @anime_main_box.visible = anime
    @book_main_box.visible = book
  end

  # commonのデータの読み込み
  def load_common_data(id)
    common = @common_controller.get_one_common(id)

    if common.is_a?(String)
      dialog_message(@window, :error, :db_error, common)
      return nil
    end

    case common.type
    when 'storage'
      @storage = common.name
    when 'rip'
      @rip = common.name
    when 'media'
      @media = common.name
    end

    common.name
  end

  # 制作会社、出版社の情報の読み込み
  def load_company_data(id)
    company = @company_controller.get_one_company(id)

    if company.is_a?(String)
      dialog_message(@window, :error, :db_error, company)
      return nil
    end

    company.name
  end

  # グループ情報の読み込み
  def load_group_data
    group = @group_controller.get_one_group(@group_id)

    if group.is_a?(String)
      dialog_message(@window, :error, :db_error, group)
      return
    end

    # グループごとに原作を読み込み、付与する
    original = load_common_data(group.original)
    @original_label.text = "原作：#{original}"
  end

  # アニメの状態のごとにボタンの切り替え
  def anime_status_btn(status_name, status = nil)
    @anime_stop_btn.label = I18n.t('view.stop_watching')
    @anime_current_entry.sensitive = false
    @anime_complete_entry.sensitive = false

    if status_name == I18n.t('view.unwatched')
      @anime_start_btn.sensitive = true
      @anime_stop_btn.sensitive = false
      @anime_save_btn.sensitive = false
      @anime_complete_btn.sensitive = false

      @anime_complete_entry.text = ''
    end

    if status_name == I18n.t('view.watching') && !status.nil?
      @anime_start_btn.sensitive = false
      @anime_stop_btn.sensitive = true
      @anime_save_btn.sensitive = true
      @anime_complete_btn.sensitive = true

      @anime_current_entry.sensitive = true
      @anime_current_entry.editable = true

      @anime_complete_entry.sensitive = true
      @anime_complete_entry.editable = true
      @anime_complete_entry.text = ''
    end

    if status_name == I18n.t('view.stop_watching') && !status.nil?
      @anime_start_btn.sensitive = false
      @anime_stop_btn.sensitive = true
      @anime_save_btn.sensitive = false
      @anime_complete_btn.sensitive = false

      @anime_stop_btn.label = I18n.t('view.restart_watching')

      @anime_complete_entry.text = ''
    end

    return unless status_name == I18n.t('view.completed') && !status.nil?

    @anime_start_btn.sensitive = false
    @anime_stop_btn.sensitive = false
    @anime_save_btn.sensitive = false
    @anime_complete_btn.sensitive = false

    @anime_complete_entry.text = status.completion_date.to_s

  end

  # 初期データの読み込み
  def load_initial_data(data)
    @content_id = data[0]['content_id']
    load_content_data(data[0]['content_id'])
    @group_id = data[0]['group_id']
    load_group_list
    load_group_data

    return if data[0]['id'].nil?

    @id = data[0]['id']
    common = load_data(data[0]['type_id'])
    db_data(common)

    @original_combo.sensitive = true

    @original_combo.model.each do |model, path, iter|
      if iter[1] == data[0]['type_id']
        @original_combo.set_active_iter(iter)
        break
      end
    end

    if @type == 'tb_anime'
      load_anime_data
    elsif @type == 'tb_book'
      load_book_data
    end

  end

  # 現状態のチェックボタンの切り替え
  def status_check_btn(original_data)
    @status_check_btn.sensitive = if [7, 10].include?(original_data)
                                    false
                                  else
                                    result = @book_controller.get_book_count_by_group_id(@type_id, @group_id)
                                    if result.is_a?(String)
                                      dialog_message(@window, :error, :db_error, result)
                                      return false
                                    end
                                    @book_count = result
                                    true
                                  end
  end

  # 現状態チェックの時、アニメの状態をチェック
  # 残ったエピソードと現在のパーセントを表示する
  def check_anime_status

    current_episode = @anime_current_entry.text.to_i
    total_episode = @anime_episode_entry.text.to_i

    remainder = total_episode - current_episode
    percentage = ((current_episode.to_f / total_episode) * 100).round(0)

    title = I18n.t('view.anime_status_check')
    message = "#{I18n.t('view.remainder')}#{remainder}\n#{I18n.t('view.percentage')}#{percentage}%"

    custom = { 'title' => title, 'message' => message }

    dialog_message(@window, :custom, nil, nil, custom)
  end

  # 現状態チェックの時、書籍の状態をチェック
  # 残った書籍の数と現在のパーセントを表示する
  def check_book_status

    completed_count = @book_controller.get_completed_book_count_by_group_id(@type_id, @group_id)

    if completed_count.is_a?(String)
      dialog_message(@window, :error, :db_error, completed_count)
      return
    end

    total_count = @book_count

    remainder = total_count - completed_count
    percentage = ((completed_count.to_f / total_count) * 100).round(0)

    title = I18n.t('view.book_status_check')
    message = "#{I18n.t('view.remainder')}#{remainder}\n#{I18n.t('view.percentage')}#{percentage}%"

    custom = { 'title' => title, 'message' => message }

    dialog_message(@window, :custom, nil, nil, custom)
  end

end
