@tool
extends EditorPlugin

const CSharpSyntaxHighlighter = preload("res://addons/csharp_syntax_highlighter/csharp_syntax_highlighter.gd")

var _highlighter: EditorSyntaxHighlighter


func _enter_tree() -> void:
	_highlighter = CSharpSyntaxHighlighter.new()
	EditorInterface.get_script_editor().register_syntax_highlighter(_highlighter)


func _exit_tree() -> void:
	if is_instance_valid(_highlighter):
		EditorInterface.get_script_editor().unregister_syntax_highlighter(_highlighter)
		_highlighter = null
