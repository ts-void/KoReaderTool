extends Panel

@onready var titel_label: Label = $RootContainer/TitelLabel
@onready var autor_label: Label = $RootContainer/AutorLabel
@onready var sprache_label: Label = $RootContainer/SpracheLabel
@onready var h_separator: HSeparator = $RootContainer/HSeparator
@onready var h_box_container: HBoxContainer = $RootContainer/HBoxContainer
@onready var label: Label = $RootContainer/HBoxContainer/Label
@onready var fortschrittsbalken: ProgressBar = $RootContainer/HBoxContainer/Fortschrittsbalken
@onready var seiten_label: Label = $RootContainer/SeitenLabel
@onready var status_label: Label = $RootContainer/StatusLabel
@onready var highlights_label: Label = $RootContainer/HighlightsLabel
@onready var notizen_label: Label = $RootContainer/NotizenLabel
@onready var hervorhebung_box: VBoxContainer = $RootContainer/HervorhebungBox
@onready var hervorhebung_label: Label = $RootContainer/HervorhebungBox/HervorhebungLabel
@onready var hervorhebung_text: RichTextLabel = $RootContainer/HervorhebungBox/HervorhebungText
@onready var h_box_container_2: HBoxContainer = $RootContainer/HBoxContainer2
@onready var neuladen_button: Button = $RootContainer/HBoxContainer2/NeuladenButton
@onready var export_button: Button = $RootContainer/HBoxContainer2/ExportButton
@onready var file_load_button: Button = $RootContainer/HBoxContainer2/FileLoadButton
@onready var h_separator_4: HSeparator = $RootContainer/HSeparator4
@onready var pfad_label: Label = $RootContainer/PfadLabel
@onready var file_dialog: FileDialog = $FileDialog


# 🔧 HIER DEN PFAD ZU DEINER metadata.epub.lua ANPASSEN!
var ebook_name = "export"
var metadata_pfad = "./metadata.epub.lua"
var highlight_content: String = ""


func _ready():
	neuladen_button.pressed.connect(_on_neuladen_pressed)
	export_button.pressed.connect(_on_export_pressed)
	file_load_button.pressed.connect(_on_open_file_dialog)
	pfad_label.text = "Pfad: " + metadata_pfad
	lade_metadaten()


func lade_metadaten():
	if not FileAccess.file_exists(metadata_pfad):
		_setze_fehlermeldung("Datei nicht gefunden: " + metadata_pfad)
		return

	var lua = LuaState.new()
	lua.open_libraries()

	var lua_code = """
		local metadata = dofile("%s")
		return metadata
	""" % metadata_pfad

	var ergebnis = lua.do_string(lua_code)

	if ergebnis == null or not (ergebnis is LuaTable):
		_setze_fehlermeldung("Fehler beim Laden der Metadaten.")
		return

	update_ui(ergebnis)


func update_ui(metadata: LuaTable):
	var doc_props = metadata.get("doc_props")
	if doc_props is LuaTable:
		titel_label.text = doc_props.get("title", "Unbekannter Titel")
		autor_label.text = "Autor: " + doc_props.get("authors", "Unbekannt")
		sprache_label.text = "Sprache: " + doc_props.get("language", "Unbekannt")
	else:
		titel_label.text = "Titel nicht verfügbar"
		autor_label.text = ""
		sprache_label.text = ""

	var percent = metadata.get("percent_finished", 0.0)
	fortschrittsbalken.value = percent * 100

	var seiten = metadata.get("doc_pages", 0)
	seiten_label.text = "Seiten: " + str(seiten)

	var summary = metadata.get("summary")
	if summary is LuaTable:
		var status = summary.get("status", "unbekannt")
		var status_text = {
			"reading": "📖 Lese gerade",
			"finished": "✅ Fertig gelesen",
			"on_hold": "⏸️ Pausiert",
			"abandoned": "❌ Abgebrochen",
		}.get(status, status.capitalize())
		status_label.text = "Status: " + status_text
		var modified = summary.get("modified", "")
		if modified != "":
			status_label.text += " (zuletzt: " + modified + ")"

	var stats = metadata.get("stats")

	_show_highlights(stats, metadata)


func _show_highlights(stats, metadata):
	if stats is LuaTable:
		var highlights = stats.get("highlights", 0)
		var notes = stats.get("notes", 0)
		highlights_label.text = "🖍️ Hervorhebungen: " + str(highlights)
		notizen_label.text = "📝 Notizen: " + str(notes)
		var annotations = metadata.get("annotations")

		_fill_highlight_box(annotations, highlights)
	else:
		highlights_label.text = "🖍️ Hervorhebungen: 0"
		notizen_label.text = "📝 Notizen: 0"
		hervorhebung_text.visible = false


func _fill_highlight_box(annotations, highlights):
	if annotations is LuaTable and highlights > 0:
		for i in range(highlights):
			var erste = annotations.get(i + 1)
			if erste is LuaTable:
				var text = erste.get("text", "")
				var seite = erste.get("pageno", 0)
				hervorhebung_text.text = hervorhebung_text.text + "Seite " + str(seite) + "\n" + text + "\n\n"
				print(hervorhebung_text.text)
				hervorhebung_text.visible = true
			else:
				hervorhebung_text.visible = false
	else:
		hervorhebung_text.visible = false
	highlight_content = hervorhebung_text.text


func _setze_fehlermeldung(msg: String):
	titel_label.text = "❌ Fehler"
	autor_label.text = ""
	sprache_label.text = ""
	fortschrittsbalken.value = 0
	seiten_label.text = ""
	status_label.text = msg
	highlights_label.text = ""
	notizen_label.text = ""
	hervorhebung_text.visible = false


func save_to_file(content, filename):
	var file = FileAccess.open(filename, FileAccess.WRITE)
	file.store_string(content)


func _on_neuladen_pressed():
	hervorhebung_text.text = ""
	lade_metadaten()


func _on_export_pressed():
	print("export to: ", ebook_name, ".txt")
	save_to_file(highlight_content, "./" + ebook_name + ".txt")


func _on_open_file_dialog():
	file_dialog.show()


func _on_file_dialog_file_selected(path: String) -> void:
	metadata_pfad = path
