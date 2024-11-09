# frozen_string_literal: true

require 'gtk3'


class RecommendDialog < Gtk::Dialog

  attr_reader :data

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

  def no_recommend
    @no_recommend_main_box = Gtk::Box.new(:vertical)
    @main_v_box.pack_start(@no_recommend_main_box, expand: true)

    @no_recommend_label = Gtk::Label.new(I18n.t('recommend.no_recommend'))
    @no_recommend_main_box.pack_start(@no_recommend_label)
  end

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

  def set_visible(no, anime, book)
    @no_recommend_main_box.visible = no
    @anime_recommend_main_box.visible = anime
    @book_recommend_main_box.visible = book
  end

  def set_signal_connect
    @recommend_button.signal_connect('clicked') do
      recommend_data
    end

    @detail_button.signal_connect('clicked') do
      response(Gtk::ResponseType::OK)
      destroy
    end

    @close_button.signal_connect('clicked') do
      response(Gtk::ResponseType::CANCEL)
      destroy
    end
  end

  def set_combo_box
    text_renderer = Gtk::CellRendererText.new
    combo_model = Gtk::ListStore.new(String, Integer)

    original = begin
                 @common_controller.get_type_menu(['original'])
               rescue StandardError => e
                 dialog_message(@window, :error, :db_error, e.message)
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

  def recommend_data
    @type_id = @original_combo.active_iter[1]

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

  def recommend_anime
    set_visible(false, true, false)

    begin
      content = @content_controller.recommend_anime

      while true
        rand_content = content.sample
        flag = false

        group_list = @group_controller.recommend_anime_by_content_id(rand_content.id)

        group_list.each do |group|
          status = @anime_controller.get_current_status(group.id)

          if status_loop(status) == 0
            @content_id = rand_content.id
            @anime_content_data.text = rand_content.name
            @group_id = group.id
            @anime_group_data.text = group.name

            flag = true
            break
          end
        end

        break if flag
      end

      recommend = @anime_controller.recommend_anime(@group_id)

      @detail_button.set_sensitive(true)
      @id = recommend.id
      @anime_data.text = recommend.name

      @data[0]['content_id'] = @content_id
      @data[0]['group_id'] = @group_id
      @data[0]['id'] = @id
      @data[0]['type_id'] = @type_id

    rescue StandardError => e
      dialog_message(@window, :error, :db_error, e.message)
      return
    end
  end

  def recommend_book
    set_visible(false, false, true)

    begin
      book = @group_controller.recommend_book(@type_id)

      while true
        rand_book = book.sample
        flag = false
        status_count = @book_controller.get_current_status(rand_book.id)

        if status_count <= 0
          temp_content = @content_controller.find_content_on_map(rand_book.id)

          content = @content_controller.get_one_content(temp_content[0]['content_id'])

          @content_id = content.id
          @book_content_data.text = content.name
          @group_id = rand_book.id
          @book_group_data.text = rand_book.name

          flag = true
        end

        break if flag

      end

      @detail_button.set_sensitive(true)
      @data = @content_id

    rescue StandardError => e
      dialog_message(@window, :error, :db_error, e.message)
      return
    end

  end

end
