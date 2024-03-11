@tool
class_name ScenesSetupDialog
extends AcceptDialog

var _tree_view : Tree
var _tree_root : TreeItem
var _file_dialog : EditorFileDialog
var _paths : Array

# ----------------------------------------------------------------------------------------------------------------------

func _enter_tree() -> void:
	_paths = ProjectSettings.get_setting(PlyEditorHackz.menuscenes_settings_key, []) as Array
	
	self.title = "Scenes Menu Setup"
	self.about_to_popup.connect(_refresh_view)
	
	_tree_view = Tree.new()
	_tree_view.columns = 2
	_tree_view.set_column_expand(0, false)
	_tree_view.set_column_expand(1, true)
	_tree_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tree_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree_view.custom_minimum_size = Vector2(300, 300)
	_tree_view.hide_root = true
	_tree_view.button_clicked.connect(_on_row_remove_button)
	_tree_root = _tree_view.create_item()
	
	var add_button := Button.new()
	add_button.text = "Add Scene or Path";
	add_button.pressed.connect(_on_add_path_button)
	
	var vbox = VBoxContainer.new()
	self.add_child(vbox)
	vbox.add_child(_tree_view)
	vbox.add_child(add_button)
	
	_file_dialog = EditorFileDialog.new()
	_file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_ANY
	_file_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_file_dialog.clear_filters()
	_file_dialog.add_filter("*.tscn")
	_file_dialog.dir_selected.connect(_on_dir_selected)
	_file_dialog.file_selected.connect(_on_file_selected)
	add_child(_file_dialog)


func _exit_tree() -> void:
	if _file_dialog: _file_dialog.queue_free()
	_file_dialog = null


func _refresh_view() -> void:
	if _paths.size() > 0:
		for idx in _paths.size():
			_set_row(idx);
			
	var rowscount := _tree_root.get_child_count()
	if rowscount > 0:
		if rowscount > _paths.size():
			for i in range(rowscount-1, _paths.size()-1, -1):
				_tree_root.get_child(i).free()


func _get_or_create_row(idx: int) -> TreeItem:
	var rowscount := _tree_root.get_child_count()
	if idx < rowscount: return _tree_root.get_child(idx)
	var row := _tree_root.create_child()
	row.add_button(0, get_theme_icon("Remove", "EditorIcons"), idx)
	return row


func _set_row(idx: int) -> void:
	var row := _get_or_create_row(idx)
	row.set_metadata(0, idx)
	row.set_text(1, _paths[idx])
	row.visible = true


func _on_add_path_button() -> void:
	_file_dialog.popup_centered(Vector2i(600, 600))


func _on_dir_selected(path: String) -> void:
	_paths.append(path)
	ProjectSettings.set_setting(PlyEditorHackz.menuscenes_settings_key, _paths)
	ProjectSettings.save()
	_set_row(_paths.size() - 1)


func _on_file_selected(path: String) -> void:
	_paths.append(path)
	ProjectSettings.set_setting(PlyEditorHackz.menuscenes_settings_key, _paths)
	ProjectSettings.save()
	_set_row(_paths.size() - 1)


func _on_row_remove_button(row: TreeItem, column: int, id: int, mouseButtonIndex: int) -> void:
	var idx := row.get_metadata(0) as int
	_paths.remove_at(idx)
	ProjectSettings.set_setting(PlyEditorHackz.menuscenes_settings_key, _paths)
	ProjectSettings.save()
	_refresh_view()


# ----------------------------------------------------------------------------------------------------------------------

