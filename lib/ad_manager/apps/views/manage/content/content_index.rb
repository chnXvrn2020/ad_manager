# frozen_string_literal: true

require_relative '../../../controllers/file_controller'
require_relative 'group_selector'
require_relative 'company_selector'
require_relative 'image_edit'
require_relative 'content_search'
require_relative 'data_selector'

class ContentIndex
  attr_reader :frame

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

    set_ui
    set_signal_connect
    initialize_window
  end

  def initialize_ui(id)
    @id = id

    content = @content_controller.get_one_content(id)

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

  def initialize_window
    initialize_no_data
    initialize_anime_data
    initialize_book_data
  end

  private

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

  def no_data
    @no_data_main_box = Gtk::Box.new(:vertical)
    @main_v_box.pack_start(@no_data_main_box, expand: true)

    @no_data_label = Gtk::Label.new(I18n.t('content.select_group'))
    @no_data_main_box.pack_start(@no_data_label)
  end

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

  def set_anime_connect
    @anime_date_entry.signal_connect('focus-out-event') do |widget, event|
      date_text = widget.text

      widget.text = '' unless date_text.match?(/^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1])$/)
    end

    @anime_episode_entry.signal_connect('changed') do |widget|
      current_text = widget.text
      widget.text = current_text.gsub(/\D/, '') unless current_text.match?(/\A\d+\z/)
    end

    @company_manage_btn.signal_connect('clicked') do
      studio_selector = CompanySelector.new(@window, @company_type, @company_ides)
      @company_ides = company_selector(studio_selector)
    end

    @anime_image_btn.signal_connect('clicked') do
      image_edit_window
    end

    @anime_list.signal_connect('button_press_event') do |widget, event|
      if event.type == Gdk::EventType::BUTTON2_PRESS
        selected_row = widget.selected_row

        if selected_row
          @content_id = selected_row.name.to_i
          data_list_clicked
        end
      end
    end

    @anime_clear_btn.signal_connect('clicked') do
      @content_id = nil
      clear_anime_data
      clear_common_data
    end

    @anime_search_btn.signal_connect('clicked') do
      content_search_btn_clicked
    end

    @anime_list_btn.signal_connect('clicked') do
      data_list_btn_clicked
    end

    @anime_add_btn.signal_connect('clicked') do
      data_add_btn_clicked
    end

    @anime_edit_button.signal_connect('clicked') do
      data_edit_btn_clicked
    end

    @anime_remove_button.signal_connect('clicked') do
      remove_btn_clicked
    end
  end

  def load_anime_frame_data
    common = %w[storage media rip ratio]

    common.each do |item|
      result = begin
        @common_controller.get_common_menu(item)
      rescue StandardError => e
        dialog_message(@window, :error, :db_error, e.message)
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
      when'storage'
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

  def load_anime_data
    anime = begin
      @anime_controller.get_anime_list(@group_id, @keyword)
    rescue StandardError => e
      dialog_message(@window, :error, :db_error, e.message)
      return
    end

    clear_list_box(@anime_list)

    anime.each do |item|
      row = Gtk::ListBoxRow.new
      row.add(Gtk::Label.new(item.name))
      row.name = item.id.to_s

      @anime_list.add(row)
    end

    @anime_list_scroll.vadjustment.value = 0.0
    @anime_list.show_all
  end

  def load_one_anime_data
    anime = begin
      @anime_controller.get_anime_by_id(@content_id)
    rescue StandardError => e
      dialog_message(@window, :error, :db_error, e.message)
      return
    end

    @anime_title_entry.text = anime.name

    combo_boxes = [@storage_combo, @media_combo, @rip_combo]
    items = [anime.storage, anime.media, anime.rip]

    array = combo_boxes.zip(items).map do |combo, item|
      { 'combo_box' => combo, 'active' => item }
    end

    combo_selector(array)

    ratio = anime.ratio.split(',').map(&:to_i)

    @ratio_box.children.each do |child|
      child.set_active(false)

      ratio.each do |item|
        child.set_active(true) if child.name == item.to_s
      end
    end

    @anime_date_entry.text = anime.created_date
    @anime_episode_entry.text = anime.episode.to_s

    studio = anime.studio.split(',').map(&:to_i)
    @company_ides = load_company_data(studio)

    @img_file = nil
    @img_del = 'N'
    @anime_edit_button.sensitive = true
    @anime_remove_button.sensitive = true
  end

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

  def set_book_connect
    @book_date_entry.signal_connect('focus-out-event') do |widget, event|
      date_text = widget.text

      widget.text = '' unless date_text.match?(/^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1])$/)
    end

    @publisher_manage_btn.signal_connect('clicked') do
      publisher_selector = CompanySelector.new(@window, @company_type, @company_ides)

      @company_ides = company_selector(publisher_selector)
    end

    @book_image_btn.signal_connect('clicked') do
      image_edit_window
    end

    @book_list.signal_connect('button_press_event') do |widget, event|
      if event.type == Gdk::EventType::BUTTON2_PRESS
        selected_row = widget.selected_row

        if selected_row
          @content_id = selected_row.name.to_i
          data_list_clicked
        end
      end
    end

    @book_clear_btn.signal_connect('clicked') do
      @content_id = nil
      clear_book_data
      clear_common_data
    end

    @book_search_btn.signal_connect('clicked') do
      content_search_btn_clicked
    end

    @book_list_btn.signal_connect('clicked') do
      data_list_btn_clicked
    end

    @book_add_btn.signal_connect('clicked') do
      data_add_btn_clicked
    end

    @book_edit_button.signal_connect('clicked') do
      data_edit_btn_clicked
    end

    @book_remove_button.signal_connect('clicked') do
      remove_btn_clicked
    end
  end

  def load_book_data
    book = begin
      type = @selected_group_original_combo.active_iter[1]
      @book_controller.get_book_list(type, @group_id, @keyword)
    rescue StandardError => e
      dialog_message(@window, :error, :db_error, e.message)
      return
    end

    clear_list_box(@book_list)

    book.each do |item|
      row = Gtk::ListBoxRow.new
      row.add(Gtk::Label.new(item.name))
      row.name = item.id.to_s

      @book_list.add(row)
    end

    @book_list_scroll.vadjustment.value = 0.0
    @book_list.show_all
  end

  def load_one_book_data
    book = begin
      @book_controller.get_book_by_id(@content_id)
    rescue StandardError => e
      dialog_message(@window, :error, :db_error, e.message)
      return
    end

    @book_title_entry.text = book.name
    @book_date_entry.text = book.created_date

    publisher = book.publisher.split(',').map(&:to_i)
    @company_ides = load_company_data(publisher)

    @img_file = nil
    @img_del = 'N'
    @book_edit_button.sensitive = true
    @book_remove_button.sensitive = true
  end

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

  def set_group_connect
    @group_list.signal_connect('button_press_event') do |widget, event|
      if event.type == Gdk::EventType::BUTTON2_PRESS
        selected_row = widget.selected_row

        if selected_row
          item = selected_row.name.to_i

          group = begin
            @group_controller.get_one_group(item)
          rescue StandardError => e
            dialog_message(@window, :error, :db_error, e.message)
            next
          end

          clear_list_box(@anime_list)
          clear_list_box(@book_list)

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

  def load_original_combo
    text_renderer = Gtk::CellRendererText.new

    @selected_group_original_combo.clear

    original = begin
      @common_controller.get_type_menu(['original'])
    rescue StandardError => e
      dialog_message(@window, :error, :db_error, e.message)
      return
    end

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

  def set_signal_connect
    @content_edit.signal_connect('clicked') do
      content = {}

      content['id'] = @id
      content['name'] = @content_title.text

      success = begin
                  @content_controller.modify_content(Content.new(content))
                rescue StandardError => e
                  dialog_message(@window, :error, :modify_error, e.message)
                  next
                end

      if success
        dialog_message(@window, :info, :modify_success)
      else
        dialog_message(@window, :warning, :duplicate_data)
      end
    end

    @content_remove.signal_connect('clicked') do
      con = confirm_dialog(:remove_confirm, @window)
      res = con.run

      if res == Gtk::ResponseType::YES
        begin
          @content_controller.remove_content(@id)
        rescue StandardError => e
          dialog_message(@window, :error, :remove_error, e.message)
          next
        end

        dialog_message(@window, :info, :remove_success)

        layout_changer = LayoutChanger.new

        layout_changer.change_layout(@stack, 1)
      end

      con.destroy
    end

    @modify_btn.signal_connect('clicked') do
      group_selector = GroupSelector.new(@window, @id)

      group_selector.signal_connect('response') do |widget, response|
        load_group_list if response == Gtk::ResponseType::OK
      end
    end

    @back_btn.signal_connect('clicked') do
      layout_changer = LayoutChanger.new

      layout_changer.change_layout(@stack, 1)
    end

    @selected_group_original_combo.signal_connect('changed') do |combo|
      @keyword = nil

      case combo.active_iter[0]
      when I18n.t('original.anime')
        frame_changer('studio', 'tb_anime', false, true, false)
        load_anime_data
      when I18n.t('original.manga'), I18n.t('original.novel')
        frame_changer('publisher', 'tb_book', false, false, true)
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

  def initialize_no_data
    @no_data_main_box.visible = true
  end

  def initialize_anime_data
    clear_anime_data
    @anime_data_main_box.visible = false
  end

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

  def initialize_book_data
    clear_book_data
    @book_data_main_box.visible = false
  end

  def clear_book_data
    @book_title_entry.text = ''
    @book_date_entry.text = ''

    @book_edit_button.sensitive = false
    @book_remove_button.sensitive = false
  end

  def clear_common_data
    @img_file = nil
    @img_del = 'N'
    @img_file_name = nil

    @company_ides = []
  end

  def frame_changer(company, content, no_data, anime, book)
    @company_type = company
    @content_type = content

    @no_data_main_box.visible = no_data
    @anime_data_main_box.visible = anime
    @book_data_main_box.visible = book
  end

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

  def data_list_clicked
    if @content_type == 'tb_anime'
      load_one_anime_data
    elsif @content_type == 'tb_book'
      load_one_book_data
    end
  end

  def load_group_list
    clear_list_box(@group_list)

    group = begin
      @group_controller.get_selected_group_list(@id)
    rescue StandardError => e
      dialog_message(@window, :error, :db_error, e.message)
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

  def load_company_data(companies)
    ides = []

    companies.each do |company|
      ides.push(company)
    end

    ides
  end

  def data_validate

    result = if @content_type == 'tb_anime'
               anime_validation
             elsif @content_type == 'tb_book'
               book_validation
             end

    unless result.is_a?(Hash)
      dialog_message(@window, :warning, result)
      return nil
    end

    result
  end

  def content_search_btn_clicked
    content_search = ContentSearch.new(@window)

    content_search.signal_connect('response') do |widget, response|
      if response == Gtk::ResponseType::OK
        @keyword = content_search.keyword

        if @content_type == 'tb_anime'
          load_anime_data
        elsif @content_type == 'tb_book'
          load_book_data
        end
      end
    end
  end

  def data_add_btn_clicked
    @keyword = nil

    if @content_type == 'tb_anime'
      anime = data_validate

      return if anime.nil?

      begin
        last_id = @anime_controller.add_anime(Anime.new(anime))

        raise if last_id.nil?

        file = file_upload(@img_file_name, @content_type, last_id)

        @file_controller.add_image_file(Files.new(file)) unless file.nil?
        @anime_controller.set_mapping_anime(@group_id, last_id)

      rescue StandardError => e
        dialog_message(@window, :error, :write_error, e.message)
        return
      end

      dialog_message(@window, :info, :write_success)

      clear_anime_data
      clear_common_data
      load_anime_data

    elsif @content_type == 'tb_book'
      book = data_validate

      return if book.nil?

      begin
        last_id = @book_controller.add_book(Book.new(book))
        raise if last_id.nil?

        file = file_upload(@img_file_name, @content_type, last_id)
        @file_controller.add_image_file(Files.new(file)) unless file.nil?
        @book_controller.set_mapping_book(@group_id, last_id)

      rescue StandardError => e
        dialog_message(@window, :error, :write_error, e.message)
        return
      end

      dialog_message(@window, :info, :write_success)

      clear_book_data
      clear_common_data
      load_book_data
    end
  end

  def data_edit_btn_clicked
    info_success = if @content_type == 'tb_anime'
                     anime = data_validate

                     return if anime.nil?

                     anime['id'] = @content_id

                     begin
                       @anime_controller.modify_anime(Anime.new(anime))
                     rescue StandardError => e
                       dialog_message(@window, :error, :modify_error, e.message)
                       return
                     end
                   elsif @content_type == 'tb_book'
                     book = data_validate

                     return if book.nil?

                     book['id'] = @content_id

                     begin
                       @book_controller.modify_book(Book.new(book))
                     rescue StandardError => e
                       dialog_message(@window, :error, :modify_error, e.message)
                       return
                     end
                   end

    img_success = image_modify

    if info_success || img_success
      dialog_message(@window, :info, :modify_success)
    else
      dialog_message(@window, :warning, :duplicate_data)
    end

    @img_file = nil
    @img_del = 'N'
    @img_file_name = nil

    load_anime_data if @content_type == 'tb_anime'
    load_book_data if @content_type == 'tb_book'
  end

  def remove_btn_clicked
    con = confirm_dialog(:remove_confirm, @window)
    res = con.run

    if res == Gtk::ResponseType::YES
      begin
        @anime_controller.remove_anime(@content_id) if @content_type == 'tb_anime'
        @book_controller.remove_book(@content_id) if @content_type == 'tb_book'
        file = {}

        file['refer_tb'] = @content_type
        file['refer_id'] = @content_id
        @file_controller.delete_image_file(Files.new(file))
      rescue StandardError => e
        dialog_message(@window, :error, :remove_error, e.message)
        return
      end

      dialog_message(@window, :info, :remove_success)

      if @content_type == 'tb_anime'
        clear_anime_data
        load_anime_data
      elsif @content_type == 'tb_book'
        clear_book_data
        load_book_data
      end
      clear_common_data
    end

    con.destroy
  end

  def image_modify
    begin
      unless @img_file_name.nil?
        file = file_upload(@img_file_name, @content_type, @content_id)
        @file_controller.modify_image_file(Files.new(file))

        return true
      end

      if @img_del == 'Y'
        file = {}

        file['refer_tb'] = @content_type
        file['refer_id'] = @content_id
        @file_controller.delete_image_file(Files.new(file))

        return true
      end

      false

    rescue StandardError => e
      dialog_message(@window, :error, :modify_error, e.message)
      false
    end
  end

  def data_list_btn_clicked
    original = @selected_group_original_combo.active_iter[1]

    data_selector = DataSelector.new(@window, @content_type, original, @group_id)

    data_selector.signal_connect('response') do |widget, response|
      if response == Gtk::ResponseType::OK
        if @content_type == 'tb_anime'
          load_anime_data
        elsif @content_type == 'tb_book'
          load_book_data
        end
      end
    end
  end
end
