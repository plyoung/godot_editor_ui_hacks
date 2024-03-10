@tool
class_name PlyEditorHackz
extends EditorPlugin

var Settings := {
	"file_system_dock/show_first_toolbar": {
		"path": "addons/editor_ui_hacks/file_system_dock/show_first_toolbar",
		"type": TYPE_BOOL,
		"default": true,
		"func": Callable(self, "_file_system_dock_show_first_toolbar"),
	},
	"file_system_dock/show_second_toolbar": {
		"path": "addons/editor_ui_hacks/file_system_dock/show_second_toolbar",
		"type": TYPE_BOOL,
		"default": true,
		"func": Callable(self, "_file_system_dock_show_second_toolbar"),
	},
	"scene_tree_dock/show_toolbar": {
		"path": "addons/editor_ui_hacks/scene_tree_dock/show_toolbar",
		"type": TYPE_BOOL,
		"default": true,
		"func": Callable(self, "_scene_tree_dock_show_toolbar"),
	},
	"editor_scene_tabs/scenes_menu": {
		"path": "addons/editor_ui_hacks/editor_scene_tabs/scenes_menu",
		"type": TYPE_BOOL,
		"default": false,
		"func": Callable(self, "_show_scenes_menubutton"),
	},
}

var _scenes_menubutton : MenuButton
var _scenes_resource_picker : EditorResourcePicker
var _scenes_setup_dialog : ScenesSetupDialog
var _scene_paths : Array[String]

const menuscenes_settings_key := "addons/editor_ui_hacks/scenes_menu"

# ----------------------------------------------------------------------------------------------------------------------
#region system

func _enter_tree() -> void:
	_setup_editor_settings()
	_add_menu_entries()
	_connect_callbacks()
	
	# wait for ui to complete init
	# todo: is there not a signal that can be awaited?
	await get_tree().create_timer(1).timeout
	_apply_ui_settings()


func _disable_plugin() -> void:
	_remove_menu_entries()
	_disconnect_callbacks()
	_remove_editor_settings()
	_reset_ui_to_default()


#endregion
# ----------------------------------------------------------------------------------------------------------------------
#region setup

func _setup_editor_settings() -> void:
	var ed_settings := EditorInterface.get_editor_settings()
	for key in Settings.keys():
		var setting : Dictionary = Settings[key]
		if !ed_settings.has_setting(setting.path):
			ed_settings.set(setting.path, setting.default)
		ed_settings.set_initial_value(setting.path, setting.default, false)
		ed_settings.add_property_info({
			"name": setting.path,
			"type": setting.type,
			"hint_string": setting.get("hint_string", null),
		})


func _remove_editor_settings() -> void:
	var ed_settings := EditorInterface.get_editor_settings()
	for key in Settings.keys():
		var setting : Dictionary = Settings[key]
		ed_settings.erase(setting.path)


func _apply_ui_settings() -> void:
	var ed_settings := EditorInterface.get_editor_settings()
	for key in Settings.keys():
		var setting : Dictionary = Settings[key]
		if ed_settings.has_setting(setting.path):
			setting["func"].call(ed_settings.get_setting(setting.path))
		else:
			setting["func"].call(setting["default"])


func _reset_ui_to_default() -> void:
	for key in Settings.keys():
		var setting : Dictionary = Settings[key]
		setting["func"].call(setting["default"])


func _connect_callbacks() -> void:
	EditorInterface.get_editor_settings().settings_changed.connect(_apply_ui_settings)
	EditorInterface.get_file_system_dock().display_mode_changed.connect(_apply_ui_settings)


func _disconnect_callbacks() -> void:
	EditorInterface.get_editor_settings().settings_changed.disconnect(_apply_ui_settings)
	EditorInterface.get_file_system_dock().display_mode_changed.disconnect(_apply_ui_settings)


#endregion
# ----------------------------------------------------------------------------------------------------------------------
#region menu entries

func _add_menu_entries() -> void:
	pass
	#var menu_bar := _get_first_node_by_class(EditorInterface.get_base_control(), "MenuBar")
	#tools_popup_menu = _get_popupmenu(menu_bar, "Project")


func _remove_menu_entries() -> void:
	pass
	#if tools_popup_menu:
		#tools_popup_menu.id_pressed.disconnect(_on_popup_menu)
		#var idx := tools_popup_menu.get_item_index(392)
		#if idx >= 0: tools_popup_menu.remove_item(idx)


func _on_popup_menu(id: int) -> void:
	pass


#endregion
# ----------------------------------------------------------------------------------------------------------------------
#region scenes menu button

func _show_scenes_menubutton(show: bool) -> void:
	if show: _add_scenes_menubutton()
	else: _remove_scenes_menubutton()
	
	
func _add_scenes_menubutton() -> void:
	if _scenes_menubutton:
		return

	# find container that the edit scene tabs and "distraction free mode" button is located in
	var editorSceneTabs := _get_first_node_by_class(EditorInterface.get_base_control(), "EditorSceneTabs")
	var hbox := _get_first_node_by_class(editorSceneTabs, "TabBar").get_parent()

	# create menu and put it next to the "distraction free mode" button
	_scenes_menubutton = MenuButton.new()
	_scenes_menubutton.text = "Scenes"	
	_scenes_menubutton.get_popup().id_pressed.connect(_on_scenes_menubutton_pressed)
	hbox.add_child(_scenes_menubutton)
	hbox.move_child(_scenes_menubutton, hbox.get_child_count() - 2)
	_refresh_scenes_menubutton_popup()

	_scenes_resource_picker = EditorResourcePicker.new()
	_scenes_resource_picker.hide()
	_scenes_resource_picker.base_type = "PackedScene"
	_scenes_resource_picker.resource_changed.connect(func(resource): EditorInterface.open_scene_from_path(resource.resource_path))
	_scenes_menubutton.add_child(_scenes_resource_picker)
	
	_scenes_setup_dialog = ScenesSetupDialog.new()
	_scenes_setup_dialog.confirmed.connect(_refresh_scenes_menubutton_popup)
	_scenes_setup_dialog.canceled.connect(_refresh_scenes_menubutton_popup)
	EditorInterface.get_base_control().add_child(_scenes_setup_dialog)


func _remove_scenes_menubutton() -> void:
	if _scenes_setup_dialog: _scenes_setup_dialog.queue_free()
	if _scenes_resource_picker: _scenes_resource_picker.queue_free()
	if _scenes_menubutton: _scenes_menubutton.queue_free()
	_scenes_menubutton = null


func _refresh_scenes_menubutton_popup() -> void:
	var menu := _scenes_menubutton.get_popup()
	menu.clear()
	menu.add_item("Setup ...", 0)
	menu.add_item("Quick Open ...", 1)
	menu.add_separator()
	
	_scene_paths.clear()
	var paths := ProjectSettings.get_setting(menuscenes_settings_key, []) as Array
	var idx := 999
	for path in paths:
		# add path to scene
		if ResourceLoader.exists(path):
			idx += 1
			_scene_paths.append(path)
			menu.add_item(path, idx)
			continue;
		# add submenu with path the scenes in folder
		var submenu := PopupMenu.new()
		submenu.name = path.json_escape().strip_escapes()
		submenu.id_pressed.connect(_on_scenes_menubutton_pressed)
		menu.add_child(submenu)
		menu.add_submenu_item(path, submenu.name)
		var file_paths := get_all_file_paths(path, "tscn")
		for file_idx in file_paths.size():
			idx += 1
			_scene_paths.append(file_paths[file_idx])
			submenu.add_item(file_paths[file_idx], idx)


func _on_scenes_menubutton_pressed(id: int) -> void:
	if id == 0: 
		_scenes_setup_dialog.popup_centered()
		return	
	if id == 1: 
		_open_scenes_quick_open()
		return
	var paths := ProjectSettings.get_setting(menuscenes_settings_key, []) as Array
	id -= 1000
	if id < _scene_paths.size():
		EditorInterface.open_scene_from_path(_scene_paths[id])


func _open_scenes_quick_open() -> void:
	# this will do a fake right-click on the resource selector to get the editor quick open dialog to come up
	var fake_right_click = InputEventMouseButton.new()
	fake_right_click.pressed = true
	fake_right_click.button_index = MOUSE_BUTTON_RIGHT
	var edit_button = _scenes_resource_picker.get_child(1)
	edit_button.gui_input.emit(fake_right_click)
	var popup = _scenes_resource_picker.get_child(2)
	popup.hide()
	popup.id_pressed.emit(1)


#endregion
# ----------------------------------------------------------------------------------------------------------------------
#region show/hide controls

func _file_system_dock_show_first_toolbar(show: bool) -> void:
	var filedock := EditorInterface.get_file_system_dock()
	var hbox := filedock.get_child(0).get_child(0)
	hbox.visible = show


func _file_system_dock_show_second_toolbar(show: bool) -> void:
	var filedock := EditorInterface.get_file_system_dock()
	var vbox := _get_first_node_by_class(filedock, "SplitContainer").get_child(1)
	if vbox.visible:
		vbox.get_child(0).visible = show
	else:
		filedock.get_child(0).get_child(1).visible = show


func _scene_tree_dock_show_toolbar(show: bool) -> void:
	# todo: this one can break easily since there is more than one case where "SceneTreeEditor" is used
	# is there a better way to find the Scene dock? Could look at the name of parent but then
	# it will only work for english. for now I am assuming it is always the 5th entry
	var scenetree_ed_nodes := EditorInterface.get_base_control().find_children("*", "SceneTreeEditor", true, false)
	var dock := scenetree_ed_nodes[5].get_parent()
	dock.get_child(0).visible = show


#endregion
# ----------------------------------------------------------------------------------------------------------------------
#region helpers

func _get_first_node_by_class(parent_node: Node, target_class_name: String) -> Node:
	if not parent_node: parent_node = EditorInterface.get_base_control()
	var nodes := parent_node.find_children("*", target_class_name, true, false)
	if !nodes.size(): return null
	return nodes[0]


func _get_first_node_by_name(parent_node: Node, target_node_name: String) -> Node:
	return parent_node.find_child(target_node_name, true, false)


func _get_popupmenu(parent_node: Node, menu_name: String) -> PopupMenu:
	var nodes := parent_node.find_children("*", "PopupMenu", true, false)
	for node in nodes:
		var menu := node as PopupMenu
		if menu and menu.name == menu_name:
			return menu
	return null


static func _print_layout_direct_children(base: Node) -> void:
	print("%s > %s" % [base.name, base.get_class()])
	var nodes := base.get_children()
	for node in nodes:
		var control = node as Control
		if control:
			var text : String = control.text if control is Label else control.tooltip_text
			print("\t%s > %s (%s) - %s" % [control.name, control.get_class(), control.visible,  text])
		else:
			print("\t%s > %s" % [node.name, node.get_class()])


static func _print_layout(base: Node, max_depth: int = -1, containers_only : bool = true, limit_non_containers : int = -1, indent: String = "") -> void:
	if base == null:
		return
		
	if max_depth > 0:
		max_depth -= 1
		if max_depth == 0: return
		
	var non_container_count := 0
	var nodes := base.get_children()
	for node in nodes:
		if containers_only:
			var control = node as Container
			if control:
				print("%s %s > %s (%s)" % [indent, control.name, control.get_class(), control.visible])
				_print_layout(node, max_depth, containers_only, limit_non_containers, indent + "\t")
		else:
			if not node is Container and limit_non_containers > 0:
				non_container_count += 1
				if non_container_count > limit_non_containers: continue
			var control = node as Control
			if control:
				print("%s %s > %s (%s) - %s" % [indent, control.name, control.get_class(), control.visible, control.tooltip_text])
			else:
				print("%s %s > %s" % [indent, node.name, node.get_class()])
			_print_layout(node, max_depth, containers_only, limit_non_containers, indent + "\t")


func get_all_file_paths(path: String, file_ext := "", recursive := false) -> Array:
	var file_paths: Array[String] = []  
	var dir = DirAccess.open(path)  
	dir.list_dir_begin()  
	var file_name = dir.get_next()  
	while file_name != "":  
		var file_path = path + "/" + file_name  
		if dir.current_is_dir():  
			if recursive:
				file_paths += get_all_file_paths(file_path, file_ext, recursive)  
		else:
			if not file_ext or file_path.get_extension() == file_ext:
				file_paths.append(file_path)  
		file_name = dir.get_next()  
	return file_paths

#endregion
# ----------------------------------------------------------------------------------------------------------------------
