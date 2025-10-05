# frozen_string_literal: true

require_relative '../../controllers/common_controller'
require_relative '../../controllers/content_controller'
require_relative '../../controllers/group_controller'
require_relative '../../controllers/anime_controller'
require_relative '../../controllers/book_controller'
require_relative 'home_search'
require_relative '../recommend/recommend_dialog'

class HomeIndex
  attr_accessor :type_combo
  attr_reader :frame

  def initialize(window, stack)
    @window = window
    @stack = stack
    @frame = Gtk::Frame.new
    @common_controller = CommonController.new
    @content_controller = ContentController.new
    @group_controller = GroupController.new
    @anime_controller = AnimeController.new
    @book_controller = BookController.new
    @pagination_num_btn = []
    @current_page = 1
    @keyword = nil
    @page = nil
    @type_id = nil
    @status_id = nil
    @book_option_id = nil

    set_ui
    load_combo_data
    set_signal_connect
  end

  def initialize_ui(_id = nil)
    @keyword = nil
    @current_page = 1

    load_list_data(@type_combo.active_iter[1], @status_combo.active_iter[1], @book_option_combo.active_iter[1])
  end

  private

  def set_ui

    main_v_box = Gtk::Box.new(:vertical)
    main_v_box.set_margin_start(50)
    main_v_box.set_margin_end(50)
    main_v_box.set_margin_top(35)
    main_v_box.set_margin_bottom(35)

    @frame.add(main_v_box)

    # １－上段のタイトルのフレイム
    top_h_box = Gtk::Box.new(:horizontal)
    main_v_box.pack_start(top_h_box, fill: true, padding: 20)

    title_label = Gtk::Label.new
    title_label.set_markup("<span font='30'>#{I18n.t('title.title')}</span>")
    top_h_box.pack_start(title_label, expand: true)

    # １－リスト欄のフレイム
    list_h_box = Gtk::Box.new(:horizontal)
    main_v_box.pack_start(list_h_box)

    # １－リスト欄内のリスト部分
    list_v_box = Gtk::Box.new(:vertical)
    list_h_box.pack_start(list_v_box, expand: true)

    @list_scroll = Gtk::ScrolledWindow.new
    @list_scroll.set_size_request(750, 450)
    list_v_box.pack_start(@list_scroll)

    @list_widget = Gtk::ListBox.new
    @list_scroll.add(@list_widget)

    # １－リスト欄内のページネーション部分
    @pagination_h_box = Gtk::Box.new(:horizontal)
    list_v_box.pack_start(@pagination_h_box, fill: true, padding: 20)

    @first_page_btn = Gtk::Button.new(label: I18n.t('pagination.first'))
    @first_page_btn.set_size_request(75, 50)
    @pagination_h_box.pack_start(@first_page_btn)

    @prev_btn = Gtk::Button.new(label: I18n.t('pagination.previous'))
    @prev_btn.set_size_request(75, 50)
    @pagination_h_box.pack_start(@prev_btn)

    @last_page_btn = Gtk::Button.new(label: I18n.t('pagination.last'))
    @last_page_btn.set_size_request(75, 50)
    @pagination_h_box.pack_end(@last_page_btn)

    @next_btn = Gtk::Button.new(label: I18n.t('pagination.next'))
    @next_btn.set_size_request(75, 50)
    @pagination_h_box.pack_end(@next_btn)

    # １－リスト欄内のコンボボックス部分
    list_v_box2 = Gtk::Box.new(:vertical, 75)
    list_h_box.pack_start(list_v_box2, padding: 20)

    @status_combo = Gtk::ComboBoxText.new
    @status_combo.set_size_request(120, 50)
    list_v_box2.pack_start(@status_combo)

    @type_combo = Gtk::ComboBoxText.new
    @type_combo.set_size_request(120, 50)
    list_v_box2.pack_start(@type_combo)

    @book_option_combo = Gtk::ComboBoxText.new
    @book_option_combo.set_size_request(120, 50)
    list_v_box2.pack_start(@book_option_combo)

    @book_option_combo.sensitive = false

    # ２ - メニューボタン
    menu_h_box = Gtk::Box.new(:horizontal)
    main_v_box.pack_start(menu_h_box, fill: true, padding: 20)

    @manage_btn = Gtk::Button.new(label: I18n.t('menu.manage'))
    @manage_btn.set_size_request(180, 50)
    menu_h_box.pack_start(@manage_btn, expand: true)

    @recommend_btn = Gtk::Button.new(label: I18n.t('menu.recommend'))
    @recommend_btn.set_size_request(180, 50)
    menu_h_box.pack_start(@recommend_btn, expand: true)

    @search_btn = Gtk::Button.new(label: I18n.t('menu.search'))
    @search_btn.set_size_request(180, 50)
    menu_h_box.pack_start(@search_btn, expand: true)

    @table_search_btn = Gtk::Button.new(label: I18n.t('menu.table_search'))
    @table_search_btn.set_size_request(180, 50)
    menu_h_box.pack_start(@table_search_btn, expand: true)

    @statistics_btn = Gtk::Button.new(label: I18n.t('menu.statistics'))
    @statistics_btn.set_size_request(180, 50)
    menu_h_box.pack_start(@statistics_btn, expand: true)

    @exit_btn = Gtk::Button.new(label: I18n.t('menu.exit'))
    @exit_btn.set_size_request(180, 50)
    menu_h_box.pack_start(@exit_btn, expand: true)
  end

  def set_signal_connect
    layout_changer = LayoutChanger.new

    @status_combo.signal_connect('changed') do |combo|
      load_list_data(@type_combo.active_iter[1], combo.active_iter[1], @book_option_combo.active_iter[1])
    end

    @type_combo.signal_connect('changed') do |combo|
      load_list_data(combo.active_iter[1], @status_combo.active_iter[1], @book_option_combo.active_iter[1])
      change_book_option_combo(combo.active_iter[1])
    end

    @book_option_combo.signal_connect('changed') do |combo|
      load_list_data(@type_combo.active_iter[1], @status_combo.active_iter[1], combo.active_iter[1])
    end

    # リストデータのダブルクリックのイベント
    @list_widget.signal_connect('button_press_event') do |widget, event|
      if event.type == Gdk::EventType::BUTTON2_PRESS
        selected_row = widget.selected_row

        if selected_row
          item = selected_row.name.to_i
          data = type_selector(item)

          if data.nil?
            view_content(item)
          else
            view_content(data)
          end
        end

      end
    end

    @manage_btn.signal_connect('clicked') do
      layout_changer.change_layout(@stack, 1)
    end

    @search_btn.signal_connect('clicked') do
      home_search = HomeSearch.new(@window, I18n.t('menu.search'), @keyword)

      home_search.signal_connect('response') do |widget, response|
        if response == Gtk::ResponseType::OK
          @keyword = home_search.keyword
          load_list_data(@type_combo.active_iter[1], @status_combo.active_iter[1], @book_option_combo.active_iter[1])
        end
      end
    end

    @recommend_btn.signal_connect('clicked') do
      recommend_dialog = RecommendDialog.new(@window)

      recommend_dialog.signal_connect('response') do |widget, response|
        if response == Gtk::ResponseType::OK
          data = recommend_dialog.data
          layout_changer.change_layout(@stack, 3, data)
        end
      end
    end

    @table_search_btn.signal_connect('clicked') do
      layout_changer.change_layout(@stack, 4)
    end

    # TODO : 索引、統計も作成

    @exit_btn.signal_connect('clicked') do
      @window.destroy
    end

    # ページネーションのオプションボタンの機能
    set_pagination_btn_signal_connect
  end

  def load_list_data(type_id, status_id, book_option_id)
    @type_id = type_id
    @status_id = status_id
    @book_option_id = book_option_id

    # Commonのデータの読み込み
    common = @common_controller.get_one_common(type_id)

    if common.is_a?(String)
      dialog_message(@window, :error, :db_error, common)
      return
    end

    # 読み込んだデータをリストに出力
    data = db_data(common)

    if data.empty?
      remove_pagination_num
      clear_list_box(@list_widget)
      return
    end

    model = data['model']
    @page = data['page']
    show_list(model)
    create_pagination(@page)

  end

  def db_data(common)

    result = case common.name
             when I18n.t('home.content')
               @content_controller.get_content_list(@current_page, @keyword, @status_id)
             when I18n.t('home.group')
               @group_controller.get_group_list_with_count(@current_page, @keyword, @status_id)
             when I18n.t('home.anime')
               @anime_controller.get_anime_list_with_count(@current_page, @keyword, @status_id)
             when I18n.t('home.manga'), I18n.t('home.novel')
               return [] if @status_id == 4 || (@status_id == 2 && @book_option_id == 33)

               if @book_option_id == 33
                 return @book_controller.get_book_list_with_count(common.id, @current_page, @keyword, @status_id)
               end

               if @book_option_id == 34
                 @type_id = 6
                 @group_controller.get_book_group_list_with_count(common.id, @current_page, @keyword, @status_id)
               end
             else
               remove_pagination_num
               clear_list_box(@list_widget)
               []
             end

    if result.is_a?(String)
      dialog_message(@window, :error, :db_error, result)
      return
    end

    result
  end

  def show_list(data)
    clear_list_box(@list_widget)

    # データをリストにインサート
    data.each do |item|
      row = Gtk::ListBoxRow.new
      row.add(Gtk::Label.new(item.name))
      row.name = item.id.to_s

      @list_widget.add(row)
    end

    # スクロールの真上に調整
    @list_scroll.vadjustment.value = 0.0

    # リストのリフレッシュ
    @list_widget.show_all

  end

  def load_combo_data
    @status_combo.clear
    @type_combo.clear
    @book_option_combo.clear

    status_renderer = Gtk::CellRendererText.new
    type_renderer = Gtk::CellRendererText.new
    book_option_renderer = Gtk::CellRendererText.new

    # コンボボックスのデータ読み込み

    param = ['h_m_1', %w[h_m_2 original], 'h_m_3']

    status_model = Gtk::ListStore.new(String, Integer)
    type_model = Gtk::ListStore.new(String, Integer)
    book_option_model = Gtk::ListStore.new(String, Integer)

    param.each_with_index do |p, i|
      list = @common_controller.get_type_menu(p)

      if list.is_a?(String)
        dialog_message(@window, :error, :db_error, list)
        return
      end

      list.each do |item|
        iter = status_model.append if i.zero?
        iter = type_model.append if i == 1
        iter = book_option_model.append if i == 2

        iter[0] = item.name
        iter[1] = item.id
      end
    end

    @status_combo.model = status_model
    @status_combo.pack_start(status_renderer, true)
    @status_combo.set_attributes(status_renderer, text: 0)
    @status_combo.active = 0

    @type_combo.model = type_model
    @type_combo.pack_start(type_renderer, true)
    @type_combo.set_attributes(type_renderer, text: 0)
    @type_combo.active = 0

    @book_option_combo.model = book_option_model
    @book_option_combo.pack_start(book_option_renderer, true)
    @book_option_combo.set_attributes(book_option_renderer, text: 0)
    @book_option_combo.active = 0
  end

  def create_pagination(page)

    # 以前のページネーションのボタンを消去
    remove_pagination_num
    page.current_page = @current_page

    # 現在のページネーションのボタンを追加
    page.page_numbers&.each do |page_num|
      page_btn = Gtk::Button.new(label: page_num.to_s)
      page_btn.set_size_request(75, 50)

      @pagination_h_box.pack_start(page_btn, expand: true)

      page_btn.sensitive = false if page_num == page.current_page

      page_btn.signal_connect('clicked') do
        @pagination_num_btn.each do |btn|
          btn.sensitive = true if btn.label == @current_page.to_s
          btn.sensitive = false if btn.label == page_num.to_s
        end

        @current_page = page_num

        common = @common_controller.get_one_common(@type_id)

        if common.is_a?(String)
          dialog_message(@window, :error, :db_error, common)
          return
        end

        data = db_data(common)
        model = data['model']

        show_list(model)
      end

      @pagination_num_btn << page_btn
    end

    # ページネーションオプションボタンの調整
    init_pagination_opt_btn(page)

    # ページネーションのボタンのリフレッシュ
    @pagination_h_box.show_all
  end

  def remove_pagination_num
    @pagination_num_btn.each do |page_btn|
      @pagination_h_box.remove(page_btn)
    end

    @pagination_num_btn.clear
  end

  def init_pagination_opt_btn(page)

    if page.page_numbers.nil? || page.total_pages <= 5
      @first_page_btn.sensitive = false
      @prev_btn.sensitive = false
      @next_btn.sensitive = false
      @last_page_btn.sensitive = false
      return
    end

    @first_page_btn.sensitive = false
    @prev_btn.sensitive = false
    @next_btn.sensitive = true
    @last_page_btn.sensitive = true

  end

  def set_pagination_opt_btn(page)
    if page.current_block <= 1
      @first_page_btn.sensitive = false
      @prev_btn.sensitive = false
    else
      @first_page_btn.sensitive = true
      @prev_btn.sensitive = true
    end

    if page.current_block >= page.total_block
      @next_btn.sensitive = false
      @last_page_btn.sensitive = false
    else
      @next_btn.sensitive = true
      @last_page_btn.sensitive = true
    end
  end

  def pagination_opt_btn_closure(click)
    proc do
      return if @page.nil?

      case click
      when :first
        @page.first_page
      when :prev
        @page.previous_page
      when :next
        @page.next_page
      when :last
        @page.last_page
      end

      create_pagination(@page)
      set_pagination_opt_btn(@page)
    end
  end

  def set_pagination_btn_signal_connect

    @first_page_btn.signal_connect('clicked', &pagination_opt_btn_closure(:first))
    @prev_btn.signal_connect('clicked', &pagination_opt_btn_closure(:prev))
    @next_btn.signal_connect('clicked', &pagination_opt_btn_closure(:next))
    @last_page_btn.signal_connect('clicked', &pagination_opt_btn_closure(:last))

  end

  def type_selector(id)
    common = @common_controller.get_one_common(@type_id)

    if common.is_a?(String)
      dialog_message(@window, :error, :db_error, common)
      return nil
    end

    result = case common.name
             when I18n.t('home.content')
               nil
             when I18n.t('home.group')
               @content_controller.find_content_on_map(id)
             else
               group = @group_controller.find_group_on_map(common, id)
               content = @content_controller.find_content_on_map(group[0]['group_id'])

               group[0]['content_id'] = content[0]['content_id']
               group[0]['type_id'] = @type_id

               group
             end

    if result.is_a?(String)
      dialog_message(@window, :error, :db_error, result)
      return nil
    end

    result
  end

  def view_content(param)
    layout_changer = LayoutChanger.new

    layout_changer.change_layout(@stack, 3, param)
  end

  def change_book_option_combo(combo)

    if combo == 8 || combo == 9
      @book_option_combo.sensitive = true
    else
      @book_option_combo.sensitive = false
    end

  end

end
