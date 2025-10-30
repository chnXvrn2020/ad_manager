# frozen_string_literal: true

require 'gtk3'


class RecommendDialog < Gtk::Dialog

  attr_reader :data

  # 初期化
  def initialize(parent)
    super(title: I18n.t('recommend.title'), parent: parent,
          flags: %i[modal destroy_with_parent])
    set_size_request(1000, 600)
    set_position(Gtk::WindowPosition::CENTER)

    self.deletable = false
    self.resizable = false

    @content_controller = ContentController.new
    @group_controller = GroupController.new
    @anime_controller = AnimeController.new
    @book_controller = BookController.new
    @common_controller = CommonController.new
    @content_id = 0
    @group_id = 0
    @id = 0
    @data = [{}]
    @type_id = 0

    set_ui
    set_signal_connect

    show_all
    set_visible(true, false, false)
  end

  # UIの設定
  def set_ui
    h_box = Gtk::Box.new(:horizontal)
    child.pack_start(h_box)

    @original_combo = Gtk::ComboBoxText.new
    @original_combo.set_size_request(150, 35)
    h_box.pack_end(@original_combo)

    set_combo_box

    @main_v_box = Gtk::Box.new(:vertical)
    @main_v_box.set_margin_start(50)
    @main_v_box.set_margin_end(50)
    @main_v_box.set_margin_top(50)
    @main_v_box.set_margin_bottom(50)
    child.pack_start(@main_v_box, expand: true)

    btn_box = Gtk::Box.new(:horizontal)
    child.pack_start(btn_box, padding: 20)

    @recommend_button = Gtk::Button.new(label: I18n.t('recommend.recommend'))
    @recommend_button.set_size_request(300, 50)
    btn_box.pack_start(@recommend_button, expand: true)

    @detail_button = Gtk::Button.new(label: I18n.t('recommend.detail'))
    @detail_button.set_size_request(300, 50)
    @detail_button.set_sensitive(false)
    btn_box.pack_start(@detail_button, expand: true)

    @close_button = Gtk::Button.new(label: I18n.t('menu.close'))
    @close_button.set_size_request(300, 50)
    btn_box.pack_start(@close_button, expand: true)

    no_recommend
    anime_recommend
    book_recommend
  end

  # 無効なデータの場合のUIの設定
  def no_recommend
    @no_recommend_main_box = Gtk::Box.new(:vertical)
    @main_v_box.pack_start(@no_recommend_main_box, expand: true)

    @no_recommend_label = Gtk::Label.new(I18n.t('recommend.no_recommend'))
    @no_recommend_main_box.pack_start(@no_recommend_label)
  end

  # アニメが選択された時のUIの設定
  def anime_recommend
    @anime_recommend_main_box = Gtk::Box.new(:vertical)
    @main_v_box.pack_start(@anime_recommend_main_box, expand: true)

    anime_content_label = Gtk::Label.new(I18n.t('recommend.content'))
    @anime_recommend_main_box.pack_start(anime_content_label)

    @anime_content_data = Gtk::Entry.new
    @anime_content_data.set_size_request(450, 30)
    @anime_content_data.editable = false
    @anime_content_data.set_alignment(0.5)
    @anime_recommend_main_box.pack_start(@anime_content_data)

    anime_group_label = Gtk::Label.new(I18n.t('recommend.group'))
    @anime_recommend_main_box.pack_start(anime_group_label)

    @anime_group_data = Gtk::Entry.new
    @anime_group_data.set_size_request(450, 30)
    @anime_group_data.editable = false
    @anime_group_data.set_alignment(0.5)
    @anime_recommend_main_box.pack_start(@anime_group_data)

    anime_data_label = Gtk::Label.new(I18n.t('recommend.anime'))
    @anime_recommend_main_box.pack_start(anime_data_label)

    @anime_data =  Gtk::Entry.new
    @anime_data.set_size_request(450, 30)
    @anime_data.editable = false
    @anime_data.set_alignment(0.5)
    @anime_recommend_main_box.pack_start(@anime_data)
  end

  # 書籍が選択された時のUIの設定
  def book_recommend
    @book_recommend_main_box = Gtk::Box.new(:vertical)
    @main_v_box.pack_start(@book_recommend_main_box, expand: true)

    book_content_label = Gtk::Label.new(I18n.t('recommend.content'))
    @book_recommend_main_box.pack_start(book_content_label)

    @book_content_data = Gtk::Entry.new
    @book_content_data.set_size_request(450, 30)
    @book_content_data.editable = false
    @book_content_data.set_alignment(0.5)
    @book_recommend_main_box.pack_start(@book_content_data)

    book_group_label = Gtk::Label.new(I18n.t('recommend.group'))
    @book_recommend_main_box.pack_start(book_group_label)

    @book_group_data = Gtk::Entry.new
    @book_group_data.set_size_request(450, 30)
    @book_group_data.editable = false
    @book_group_data.set_alignment(0.5)
    @book_recommend_main_box.pack_start(@book_group_data)
  end

  # UIフレイムの表示・非表示の切り替え
  def set_visible(no, anime, book)
    @no_recommend_main_box.visible = no
    @anime_recommend_main_box.visible = anime
    @book_recommend_main_box.visible = book
  end

  # UIウィゼットの設定
  def set_signal_connect
    # 推薦ボタンのクリックイベント
    @recommend_button.signal_connect('clicked') do
      recommend_data
    end

    # 詳細ボタンのクリックイベント
    @detail_button.signal_connect('clicked') do
      response(Gtk::ResponseType::OK)
      destroy
    end

    # 閉じるボタンのクリックイベント
    @close_button.signal_connect('clicked') do
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

  # 推薦ボタンのクリックイベントの処理
  def recommend_data
    @type_id = @original_combo.active_iter[1]

    # 種別によって分岐する
    case @type_id
    when 7
      recommend_anime
    when 8,9
      recommend_book
    when 0
      set_visible(true, false, false)
      @no_recommend_label.text = I18n.t('recommend.no_original')
    else
      set_visible(true, false, false)
      @no_recommend_label.text = I18n.t('recommend.no_support')
    end
  end

  # アニメ推薦の処理
  def recommend_anime
    set_visible(false, true, false)
    @data = [{}]

    result = @anime_controller.recommend_anime

    if result.is_a?(String)
      dialog_message(@window, :error, :db_error, result)
      return
    end

    @content_id = result['content_id']
    @anime_content_data.text = result['anime_content_data']
    @group_id = result['group_id']
    @anime_group_data.text = result['anime_group_data']

    @detail_button.set_sensitive(true)
    @id = result['recommend_id']
    @anime_data.text = result['recommend_name']

    @data[0]['content_id'] = @content_id
    @data[0]['group_id'] = @group_id
    @data[0]['id'] = @id
    @data[0]['type_id'] = @type_id
  end

  # 書籍推薦の処理
  def recommend_book
    set_visible(false, false, true)
    @data = [{}]

    result = @book_controller.recommend_book(@type_id)

    if result.is_a?(String)
      dialog_message(@window, :error, :db_error, result)
      return
    end

    @content_id = result['content_id']
    @book_content_data.text = result['book_content_data']
    @group_id = result['group_id']
    @book_group_data.text = result['book_group_data']

    @detail_button.set_sensitive(true)
    @data = @content_id

  end

end
