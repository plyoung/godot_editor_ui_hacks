@tool
extends EditorPlugin

var Settings := {
	"file_system_dock/show_first_toolbar": {
		"path": "addons/editor_ui_hacks/file_system_dock/show_first_toolbar",
		"type": TYPE_BOOL,
		"default": true,
		"func": Callable(self, "file_system_dock_show_first_toolbar"),
	},
	"file_system_dock/show_second_toolbar": {
		"path": "addons/editor_ui_hacks/file_system_dock/show_second_toolbar",
		"type": TYPE_BOOL,
		"default": true,
		"func": Callable(self, "file_system_dock_show_second_toolbar"),
	},
	"scene_tree_dock/show_toolbar": {
		"path": "addons/editor_ui_hacks/scene_tree_dock/show_toolbar",
		"type": TYPE_BOOL,
		"default": true,
		"func": Callable(self, "scene_tree_dock_show_toolbar"),
	},
}

## ----------------------------------------------------------------------------

func _enter_tree() -> void:
	_setup_editor_settings()
	_connect_callbacks()
	# wait for ui to complete init
	# todo: is there not a signal that can be awaited?
	await get_tree().create_timer(1).timeout
	_apply_ui_settings()


func _disable_plugin() -> void:
	_disconnect_callbacks()
	_remove_editor_settings()
	_reset_ui_to_default()


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


## ----------------------------------------------------------------------------

func file_system_dock_show_first_toolbar(show: bool) -> void:
	var filedock := EditorInterface.get_file_system_dock()
	var hbox := filedock.get_child(0).get_child(0)
	hbox.visible = show


func file_system_dock_show_second_toolbar(show: bool) -> void:
	var filedock := EditorInterface.get_file_system_dock()
	var vbox := _get_first_node_by_class(filedock, "SplitContainer").get_child(1)
	if vbox.visible:
		vbox.get_child(0).visible = show
	else:
		filedock.get_child(0).get_child(1).visible = show


func scene_tree_dock_show_toolbar(show: bool) -> void:
	# todo: this one is messy since there is more than one case where "SceneTreeEditor" is used
	# is there a better way to find the Scene dock? Could look at the name of parent but then
	# it will only work for english. for now I am assuming it is always the 5th entry
	var scenetree_ed_nodes := EditorInterface.get_base_control().find_children("*", "SceneTreeEditor", true, false)
	var dock := scenetree_ed_nodes[5].get_parent()
	dock.get_child(0).visible = show


## ----------------------------------------------------------------------------

func _get_first_node_by_class(parent_node : Node, target_class_name : String) -> Node:
	var nodes := parent_node.find_children("*", target_class_name, true, false)
	if !nodes.size(): return null
	return nodes[0]


func _print_layout(base: Node, indent: String, containers_only : bool = true) -> void:
	var nodes := base.get_children()
	for node in nodes:
		if containers_only:
			var control = node as Container
			if control:
				print("%s %s > %s (%s)" % [indent, control.name, control.get_class(), control.visible])
				_print_layout(node, indent + "\t", containers_only)
		else:
			var control = node as Control
			if control:
				print("%s %s > %s (%s) - %s" % [indent, control.name, control.get_class(), control.visible, control.tooltip_text])
			else:
				print("%s %s > %s" % [indent, node.name, node.get_class()])
			_print_layout(node, indent + "\t", containers_only)

## ----------------------------------------------------------------------------
