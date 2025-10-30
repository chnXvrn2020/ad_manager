# frozen_string_literal: true

require_relative '../../controllers/company_controller'
require_relative 'common_edit'
require_relative 'company/company_index'

class ManageIndex
  attr_reader :frame

  # 初期化
  def initialize(window, stack)
    @window = window
    @stack = stack
    @frame = Gtk::Frame.new
    @common_controller = CommonController.new
    @company_controller = CompanyController.new
    @content_controller = ContentController.new
    @pagination_num_btn = []
    @radio_active = nil
    @current_page = 1
    @keyword = nil
    @page = nil
    @radio_btn = []

    set_ui
    set_signal_connect
  end

  # UIの初期化
  def initialize_ui(_id = nil)
    @radio_active = @radio_btn[0] if @radio_active.nil?
    @keyword = nil
    load_data
  end

  private

  # UIの設定
  def set_ui
    main_v_box = Gtk::Box.new(:vertical)
    main_v_box.set_margin_start(50)
    main_v_box.set_margin_end(50)
    main_v_box.set_margin_top(35)
    main_v_box.set_margin_bottom(35)
    @frame.add(main_v_box)

    # １－リスト欄のフレイム
    list_h_box = Gtk::Box.new(:horizontal)
    main_v_box.pack_start(list_h_box, padding: 10)

    # １－リスト欄内のリスト部分
    list_v_box = Gtk::Box.new(:vertical)
    list_h_box.pack_start(list_v_box, expand: true)

    @list_scroll = Gtk::ScrolledWindow.new
    @list_scroll.set_size_request(850, 550)
    list_v_box.pack_start(@list_scroll)

    @list_widget = Gtk::ListBox.new
    @list_scroll.add(@list_widget)

    # ２－リスト欄内のページネーション部分
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

    @first_page_btn.sensitive = false
    @prev_btn.sensitive = false
    @next_btn.sensitive = false
    @last_page_btn.sensitive = false

    # ２－リスト欄のラジオボタン部分
    radio_v_box = Gtk::Box.new(:vertical, 40)
    list_h_box.pack_start(radio_v_box)

    radio_text = [I18n.t('radio_menu.content'), I18n.t('radio_menu.studio'), I18n.t('radio_menu.publisher'),
                  I18n.t('radio_menu.storage'), I18n.t('radio_menu.rip'), I18n.t('radio_menu.media'),
                  I18n.t('radio_menu.ratio'), I18n.t('radio_menu.original')]

    radio_text.each_with_index do |text, index|
      @radio_btn[index] = if index.zero?
                            Gtk::RadioButton.new(label: text)
                          else
                            Gtk::RadioButton.new(label: text, member: @radio_btn[0])
                          end

      radio_v_box.pack_start(@radio_btn[index])
    end

    # 3－下のボタン部分
    btn_h_box = Gtk::Box.new(:horizontal)
    main_v_box.pack_start(btn_h_box, padding: 10)

    @add_btn = Gtk::Button.new(label: I18n.t('menu.add'))
    @add_btn.set_size_request(350, 50)
    btn_h_box.pack_start(@add_btn)

    @search_btn = Gtk::Button.new(label: I18n.t('menu.search'))
    @search_btn.set_size_request(350, 50)
    btn_h_box.pack_start(@search_btn)

    @back_btn = Gtk::Button.new(label: I18n.t('menu.back'))
    @back_btn.set_size_request(350, 50)
    btn_h_box.pack_start(@back_btn)

  end

  # ウィゼットの設定
  def set_signal_connect
    layout_changer = LayoutChanger.new

    # リストのダブルクリックイベント
    @list_widget.signal_connect('button_press_event') do |widget, event|
      if event.type == Gdk::EventType::BUTTON2_PRESS
        selected_row = widget.selected_row

        if selected_row
          item = selected_row.name.to_i

          # 各種ごとに分岐する
          result = case @radio_active.label
                   when I18n.t('radio_menu.content')
                     # ContentIndexへと切り替える
                     layout_changer.change_layout(@stack, 2, item)
                     nil
                   when I18n.t('radio_menu.studio'), I18n.t('radio_menu.publisher')
                     CompanyIndex.new(@window, @radio_active, item)
                   else
                     CommonEdit.new(@window, I18n.t('menu.modify'), @radio_active, item)
                   end

          # nilじゃない場合、新しいダイアログを表示する
          result&.signal_connect('response') do |widget, response|
            load_data if response == Gtk::ResponseType::OK
          end
        end
      end
    end

    # ラジオボタンのクリックイベント
    @radio_btn.each do |radio|
      radio.signal_connect('toggled') do
        if radio.active?
          @radio_active = radio
          @current_page = 1
          @keyword = nil

          load_data
        end
      end
    end

    # 登録ボタンのクリックイベント
    @add_btn.signal_connect('clicked') do
      common_edit = CommonEdit.new(@window, @add_btn.label, @radio_active)

      common_edit.signal_connect('response') do |widget, response|
        if response == Gtk::ResponseType::OK
          # last_idがnilじゃない場合、レイアウトを遷移する
          # nilの場合は、データを読み込む
          if !common_edit.last_id.nil?
            # ContentIndexへと切り替える
            layout_changer.change_layout(@stack, 2, common_edit.last_id)
          else
            load_data
          end
        end
      end
    end

    # 検索ボタンのクリックイベント
    @search_btn.signal_connect('clicked') do
      common_edit = CommonEdit.new(@window, @search_btn.label, @radio_active)

      common_edit.signal_connect('response') do |widget, response|
        if response == Gtk::ResponseType::OK
          @keyword = common_edit.keyword
          @current_page = 1

          load_data
        end
      end

    end

    # 戻るボタンのクリックイベント
    @back_btn.signal_connect('clicked') do
      layout_changer.change_layout(@stack, 0)
    end

    # ページネーションのオプションボタンの機能
    set_pagination_btn_signal_connect
  end

  # データ読み込みの処理
  def load_data
    # データを読み込む
    result = db_data

    # 空の場合、何もしない
    return if result.empty?

    # 結果データを変数に入力
    model = result['model']
    @page = result['page']

    # リストの表示
    show_list(model)
    # ページネーションの表示
    create_pagination(@page)

  end

  # ページネーションの表示
  def create_pagination(page)

    # 以前のページネーションのボタンをクリア
    remove_pagination_num
    page.current_page = @current_page

    # 現在のページネーションのボタンを追加
    page.page_numbers&.each do |page_num|
      page_btn = Gtk::Button.new(label: page_num.to_s)
      page_btn.set_size_request(75, 50)

      @pagination_h_box.pack_start(page_btn, expand: true)

      page_btn.sensitive = false if page_num == page.current_page

      # ページネーションのボタンのクリックイベント
      page_btn.signal_connect('clicked') do
        # ページネーションのボタンの色を変える
        @pagination_num_btn.each do |btn|
          btn.sensitive = true if btn.label == @current_page.to_s
          btn.sensitive = false if btn.label == page_num.to_s
        end

        # 現在ページを更新する
        @current_page = page_num

        # 新たなページのデータを読み込む
        data = db_data
        model = data['model']

        show_list(model)
      end

      # ページネーションのボタンを配列に追加
      @pagination_num_btn << page_btn
    end

    # ページネーションオプションボタンの調整
    init_pagination_opt_btn(page)

    # ページネーションのボタンのリフレッシュ
    @pagination_h_box.show_all
  end

  # 現在のページネーションのボタンをクリアする
  def remove_pagination_num
    @pagination_num_btn.each do |page_btn|
      @pagination_h_box.remove(page_btn)
    end

    @pagination_num_btn.clear
  end

  # ページネーションオプションボタンの初期化
  def init_pagination_opt_btn(page)
    # 最初のページブロックの場合、前のボタンは無効
    # ページネーションの数が5以下でなら、次のボタンも無効
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

  # ページネーションオプションボタンの調整
  def set_pagination_opt_btn(page)
    # 最初のページブロックの場合、前のボタンは無効
    if page.current_block <= 1
      @first_page_btn.sensitive = false
      @prev_btn.sensitive = false
    else
      @first_page_btn.sensitive = true
      @prev_btn.sensitive = true
    end

    # ページブロックの最後の場合、次のボタンは無効
    if page.current_block >= page.total_block
      @next_btn.sensitive = false
      @last_page_btn.sensitive = false
    else
      @next_btn.sensitive = true
      @last_page_btn.sensitive = true
    end
  end

  # ページネーションオプションボタンのクリックイベントの処理
  def pagination_opt_btn_closure(click)
    proc do
      return if @page.nil?

      # pageのmodelの関数に渡してページを返す
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

  # ページネーションのオプションボタンのクリックイベント
  def set_pagination_btn_signal_connect

    @first_page_btn.signal_connect('clicked', &pagination_opt_btn_closure(:first))
    @prev_btn.signal_connect('clicked', &pagination_opt_btn_closure(:prev))
    @next_btn.signal_connect('clicked', &pagination_opt_btn_closure(:next))
    @last_page_btn.signal_connect('clicked', &pagination_opt_btn_closure(:last))

  end

  # リストのデータの表示
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

  # DBからデータを読み込む
  def db_data
    # 各種ごとに分岐する
    result = case @radio_active.label
             when I18n.t('radio_menu.content')
               @content_controller.get_content_list(@current_page, @keyword)
             when I18n.t('radio_menu.studio'), I18n.t('radio_menu.publisher')
               @company_controller.get_company_list(@radio_active.label, @current_page, @keyword)
             else
               @common_controller.get_common_list(@radio_active.label, @current_page, @keyword)
             end

    if result.is_a?(String)
            dialog_message(@window, :error, :db_error, result)
            []
    else
            result
    end
  end
end
