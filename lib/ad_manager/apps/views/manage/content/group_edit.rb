# frozen_string_literal: true

require_relative '../../../controllers/group_controller'
require_relative '../../../controllers/common_controller'

require 'gtk3'

class GroupEdit < Gtk::Dialog

  attr_reader :param

  def initialize(parent, menu, id = nil)
    super(title: menu, parent: parent,
          flags: %i[modal destroy_with_parent])
    set_size_request(700, 200)
    set_position(Gtk::WindowPosition::CENTER)

    self.deletable = false
    self.resizable = false

    @oarent = parent
    @menu = menu
    @id = id
    @group_controller = GroupController.new
    @common_controller = CommonController.new

    set_ui
    close_btn_ui
    set_signal_connect

    show_all
  end

  def set_ui

    h_box = Gtk::Box.new(:horizontal)
    child.pack_start(h_box, padding: 10)

    @entry = Gtk::Entry.new
    @entry.set_size_request(500, 35)
    @entry.grab_focus
    h_box.pack_start(@entry, expand: true)

    @original_combo = Gtk::ComboBoxText.new
    @original_combo.set_size_request(150, 35)
    h_box.pack_start(@original_combo)

    @btn_box = Gtk::Box.new(:horizontal)
    child.pack_start(@btn_box, padding: 30)

    set_combo_box

    case @menu
    when I18n.t('menu.add')
      add_ui
      set_add_widgets_connect
    when I18n.t('menu.search')
      search_ui
      set_search_widgets_connect
    when I18n.t('menu.modify')
      modify_ui
      load_data
      set_modify_widgets_connect
    else
      response(Gtk::ResponseType::CANCEL)
      destroy
    end
  end

  def add_ui
    @add_button = Gtk::Button.new(label: I18n.t('menu.add'))
    @add_button.set_size_request(270, 50)
    @btn_box.pack_start(@add_button, expand: true)
  end

  def search_ui
    @search_button = Gtk::Button.new(label: I18n.t('menu.search'))
    @search_button.set_size_request(270, 50)
    @btn_box.pack_start(@search_button, expand: true)
  end

  def modify_ui
    @modify_button = Gtk::Button.new(label: I18n.t('menu.modify'))
    @modify_button.set_size_request(150, 50)
    @btn_box.pack_start(@modify_button, expand: true)

    @remove_button = Gtk::Button.new(label: I18n.t('menu.remove'))
    @remove_button.set_size_request(150, 50)
    @btn_box.pack_start(@remove_button, expand: true)
  end

  def close_btn_ui
    @close_button = Gtk::Button.new(label: I18n.t('menu.close'))
    @close_button.set_size_request(270, 50)
    @btn_box.pack_start(@close_button, expand: true)
  end

  def set_signal_connect
    signal_connect('key_press_event') do |widget, event|
      if event.keyval == Gdk::Keyval::KEY_Return ||
        event.keyval == Gdk::Keyval::KEY_KP_Enter

        case @menu
        when I18n.t('menu.add')
          @add_button.clicked
        when I18n.t('menu.search')
          @search_button.clicked
        when I18n.t('menu.modify')
          @modify_button.clicked
        else
          response(Gtk::ResponseType::CANCEL)
          destroy
        end

      end
      false
    end

    @close_button.signal_connect('clicked') do
      response(Gtk::ResponseType::OK)
      destroy
    end
  end

  def set_add_widgets_connect
    @add_button.signal_connect('clicked') do
      if @entry.text.to_s.strip.empty?
        dialog_message(self, :warning, :empty_entry)
        next
      end

      original = @original_combo.active_iter[1]

      if original.zero?
        dialog_message(self, :warning, :empty_original)
        next
      end

      group = { 'original' => original, 'name' => @entry.text.to_s.strip }

      begin
        success = @group_controller.add_group(Group.new(group))
      rescue StandardError => e
        dialog_message(self, :error, :write_error, e.message)
        next
      end

      if success
        dialog_message(self, :info, :write_success)

        response(Gtk::ResponseType::OK)
        destroy
      else
        dialog_message(self, :warning, :duplicate_data)
        @entry.grab_focus
      end
    end
  end

  def set_search_widgets_connect
    @search_button.signal_connect('clicked') do
      keyword = @entry.text.to_s.strip
      original = @original_combo.active_iter[1]

      @param = { 'keyword' => keyword, 'original' => original }

      response(Gtk::ResponseType::OK)
      destroy
    end
  end

  def set_modify_widgets_connect
    @modify_button.signal_connect('clicked') do
      if @entry.text.to_s.strip.empty?
        dialog_message(self, :warning, :empty_entry)
        next
      end

      original = @original_combo.active_iter[1]

      if original.zero?
        dialog_message(self, :warning, :empty_original)
        next
      end

      group = { 'id' => @id, 'original' => original, 'name' => @entry.text.to_s.strip }

      begin
        success = @group_controller.modify_one_group(Group.new(group))
      rescue StandardError => e
        dialog_message(self, :error, :modify_error, e.message)
        next
      end

      if success
        dialog_message(self, :info, :modify_success)
      else
        dialog_message(self, :warning, :duplicate_data)
        @entry.grab_focus
      end
    end

    @remove_button.signal_connect('clicked') do
      con = confirm_dialog(:remove_confirm, self)
      res = con.run

      if res == Gtk::ResponseType::YES
        begin
          @group_controller.remove_one_group(@id)

          dialog_message(self, :info, :remove_success)

          response(Gtk::ResponseType::OK)
          destroy
        rescue StandardError => e
          dialog_message(self, :error, :remove_error, e.message)
          next
        end
      end

      con.destroy
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

  def load_data
    group = begin
      @group_controller.get_one_group(@id)
    rescue StandardError => e
      dialog_message(@window, :error, :db_error, e.message)
      return
    end

    @entry.text = group.name

    @original_combo.model.each do |model, path, iter|
      if iter[1] == group.original
        @original_combo.set_active_iter(iter)
        break
      end
    end

  end
end
