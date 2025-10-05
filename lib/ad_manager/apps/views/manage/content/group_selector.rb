# frozen_string_literal: true

require_relative '../../../controllers/group_controller'
require_relative 'group_edit'

require 'gtk3'

class GroupSelector < Gtk::Dialog

  def initialize(parent, id)
    super(title: I18n.t('group.title'), parent: parent,
          flags: %i[modal destroy_with_parent])
    set_size_request(1000, 500)
    set_position(Gtk::WindowPosition::CENTER)

    self.deletable = false
    self.resizable = false

    @id = id
    @controller = GroupController.new
    @mode = 'add'
    @group_list_mode = 'only'
    @param = nil

    set_ui
    load_group_data
    load_selected_group_data
    set_signal_connect

    show_all
  end

  def set_ui
    h_box = Gtk::Box.new(:horizontal)
    child.pack_start(h_box, padding: 10)

    label = Gtk::Label.new
    label.set_markup("<span font='25'>#{I18n.t('group.title')}</span>")
    h_box.pack_start(label, expand: true)

    @group_list_btn = Gtk::Button.new(label: I18n.t('group.only_list'))
    @group_list_btn.set_size_request(150, 25)
    h_box.pack_start(@group_list_btn)

    @mode_chg_btn = Gtk::Button.new(label: I18n.t('group.add_mode'))
    @mode_chg_btn.set_size_request(150, 25)
    h_box.pack_start(@mode_chg_btn)

    list_h_box = Gtk::Box.new(:horizontal)
    child.pack_start(list_h_box, padding: 20)

    selected_list_v_box = Gtk::Box.new(:vertical)
    list_h_box.pack_start(selected_list_v_box, expand: true)

    selected_label = Gtk::Label.new
    selected_label.text = I18n.t('group.selected')
    selected_list_v_box.pack_start(selected_label)

    @selected_list_scroll = Gtk::ScrolledWindow.new
    @selected_list_scroll.set_size_request(400, 300)
    selected_list_v_box.pack_start(@selected_list_scroll, expand: true)

    @selected_list = Gtk::ListBox.new
    @selected_list_scroll.add(@selected_list)

    group_list_v_box = Gtk::Box.new(:vertical)
    list_h_box.pack_start(group_list_v_box, expand: true)

    group_label = Gtk::Label.new
    group_label.text = I18n.t('group.not_selected')
    group_list_v_box.pack_start(group_label)

    @group_list_scroll = Gtk::ScrolledWindow.new
    @group_list_scroll.set_size_request(400, 300)
    group_list_v_box.pack_start(@group_list_scroll, expand: true)

    @group_list = Gtk::ListBox.new
    @group_list_scroll.add(@group_list)

    btn_h_box = Gtk::Box.new(:horizontal)
    child.pack_start(btn_h_box, padding: 20)

    @add_btn = Gtk::Button.new(label: I18n.t('menu.add'))
    @add_btn.set_size_request(220, 50)
    btn_h_box.pack_start(@add_btn, expand: true)

    @search_btn = Gtk::Button.new(label: I18n.t('menu.search'))
    @search_btn.set_size_request(220, 50)
    btn_h_box.pack_start(@search_btn, expand: true)

    @close_button = Gtk::Button.new(label: I18n.t('menu.close'))
    @close_button.set_size_request(220, 50)
    btn_h_box.pack_start(@close_button, expand: true)
  end

  def set_signal_connect
    @mode_chg_btn.signal_connect('clicked') do
      if @mode == 'add'
        @mode = 'modify'
        @mode_chg_btn.label = I18n.t('group.modify_mode')
      elsif @mode == 'modify'
        @mode = 'add'
        @mode_chg_btn.label = I18n.t('group.add_mode')
      end
    end

    @group_list_btn.signal_connect('clicked') do
      if @group_list_mode == 'only'
        @group_list_mode = 'all'
        @group_list_btn.label = I18n.t('group.all_list')
      elsif @group_list_mode == 'all'
        @group_list_mode = 'only'
        @group_list_btn.label = I18n.t('group.only_list')
      end
      load_group_data
    end

    @group_list.signal_connect('button_press_event') do |widget, event|
      if event.type == Gdk::EventType::BUTTON2_PRESS
        selected_row = widget.selected_row

        if selected_row
          item = selected_row.name.to_i

          if @mode == 'add'
            add_group(widget, item, selected_row)
          elsif @mode == 'modify'
            modify_group(item)
          end
        end
      end
    end

    @selected_list.signal_connect('button_press_event') do |widget, event|
      if event.type == Gdk::EventType::BUTTON2_PRESS
        selected_row = widget.selected_row
        if selected_row
          item = selected_row.name.to_i

          if @mode == 'add'
            remove_selected_group(widget, item, selected_row)
          elsif @mode == 'modify'
            modify_selected_group(item)
          end
        end
      end
    end

    @add_btn.signal_connect('clicked') do
      group_edit = GroupEdit.new(self, @add_btn.label)

      group_edit.signal_connect('response') do |widget, response|
        load_group_data if response == Gtk::ResponseType::OK
      end
    end

    @search_btn.signal_connect('clicked') do
      group_edit = GroupEdit.new(self, @search_btn.label)

      group_edit.signal_connect('response') do |widget, response|
        if response == Gtk::ResponseType::OK
          @param = group_edit.param

          @group_list_mode = 'all'
          @group_list_btn.label = I18n.t('group.all_list')
          load_group_data
        end
      end
    end

    @close_button.signal_connect('clicked') do
      response(Gtk::ResponseType::OK)
      destroy
    end
  end

  def add_group(widget, item, selected_row)
    result = @controller.set_mapping_group(@id, item)

    if result.is_a?(String)
      dialog_message(self, :error, :db_error, result)
      return
    end

    row = Gtk::ListBoxRow.new
    row.add(Gtk::Label.new(selected_row.child.text))
    row.name = item.to_s
    row.halign = Gtk::Align::START

    @selected_list.add(row)
    @selected_list.show_all

    widget.remove(selected_row)
  end

  def modify_group(item)
    group_edit = GroupEdit.new(self, I18n.t('menu.modify'), item)

    group_edit.signal_connect('response') do |widget, response|
      load_group_data if response == Gtk::ResponseType::OK
    end
  end

  def remove_selected_group(widget, item, selected_row)
    result = @controller.remove_mapping_group(@id, item)

    if result.is_a?(String)
      dialog_message(self, :error, :db_error, e.message)
      return
    end

    row = Gtk::ListBoxRow.new
    row.add(Gtk::Label.new(selected_row.child.text))
    row.name = item.to_s
    row.halign = Gtk::Align::START

    @group_list.add(row)

    @group_list.set_sort_func do |row1, row2|
      row1.child.text <=> row2.child.text
    end

    @group_list.show_all

    widget.remove(selected_row)
  end

  def modify_selected_group(item)
    group_edit = GroupEdit.new(self, I18n.t('menu.modify'), item)

    group_edit.signal_connect('response') do |widget, response|
      load_selected_group_data if response == Gtk::ResponseType::OK
    end
  end

  def load_group_data
    clear_list_box(@group_list)

    group = if @group_list_mode == 'all'
              @controller.get_group_list(@id, @param)
            elsif @group_list_mode == 'only'
              @controller.get_group_list(nil, @param)
            end

    if group.is_a?(String)
      dialog_message(self, :error, :db_error, group)
      return
    end

    group.each do |item|
      row = Gtk::ListBoxRow.new
      row.add(Gtk::Label.new(item.name + "　（#{item.original_name}）"))
      row.name = item.id.to_s
      row.halign = Gtk::Align::START

      @group_list.add(row)
    end

    @group_list.show_all
  end

  def load_selected_group_data
    clear_list_box(@selected_list)

    selected_group = @controller.get_selected_group_list(@id)

    if selected_group.is_a?(String)
      dialog_message(self, :error, :db_error, e.message)
      return
    end

    selected_group.each do |item|
      row = Gtk::ListBoxRow.new
      row.add(Gtk::Label.new(item.name + "　（#{item.original_name}）"))
      row.name = item.id.to_s
      row.halign = Gtk::Align::START

      @selected_list.add(row)
    end

    @selected_list.show_all
  end
end
