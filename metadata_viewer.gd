extends Panel

@onready var titel_label = $VBoxContainer/TitelLabel
@onready var autor_label = $VBoxContainer/AutorLabel
@onready var sprache_label = $VBoxContainer/SpracheLabel
@onready var fortschrittsbalken = $VBoxContainer/HBoxContainer/Fortschrittsbalken
@onready var seiten_label = $VBoxContainer/SeitenLabel
@onready var status_label = $VBoxContainer/StatusLabel
@onready var highlights_label = $VBoxContainer/HighlightsLabel
@onready var notizen_label = $VBoxContainer/NotizenLabel
@onready var hervorhebung_text = $VBoxContainer/HervorhebungBox/HervorhebungText
@onready var neuladen_button = $VBoxContainer/NeuladenButton
@onready var pfad_label = $VBoxContainer/PfadLabel

var metadata_pfad = "/home/ts/Books/Nagel/WhatIsItLikeToBeABat/WhatIsItLikeToBeABat.sdr/metadata.epub.lua"

func _ready():
	neuladen_button.pressed.connect(_on_neuladen_pressed)
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
	fortschrittsbalken.text = str(round(percent * 100)) + "%"
	
	var seiten = metadata.get("doc_pages", 0)
	seiten_label.text = "Seiten: " + str(seiten)
	
	var summary = metadata.get("summary")
	if summary is LuaTable:
		var status = summary.get("status", "unbekannt")
		var status_text = {
			"reading": "📖 Lese gerade",
			"finished": "✅ Fertig gelesen",
			"on_hold": "⏸️ Pausiert",
			"abandoned": "❌ Abgebrochen"
		}.get(status, status.capitalize())
		status_label.text = "Status: " + status_text
		var modified = summary.get("modified", "")
		if modified != "":
			status_label.text += " (zuletzt: " + modified + ")"
	
	var stats = metadata.get("stats")
	if stats is LuaTable:
		var highlights = stats.get("highlights", 0)
		var notes = stats.get("notes", 0)
		highlights_label.text = "🖍️ Hervorhebungen: " + str(highlights)
		notizen_label.text = "📝 Notizen: " + str(notes)
		
		var annotations = metadata.get("annotations")
		if annotations is LuaTable and highlights > 0:
			var erste = annotations.get(1)
			if erste is LuaTable:
				var text = erste.get("text", "")
				var seite = erste.get("pageno", 0)
				hervorhebung_text.text = "[b]Seite " + str(seite) + ":[/b]\n" + text
				hervorhebung_text.visible = true
			else:
				hervorhebung_text.visible = false
		else:
			hervorhebung_text.visible = false
	else:
		highlights_label.text = "🖍️ Hervorhebungen: 0"
		notizen_label.text = "📝 Notizen: 0"
		hervorhebung_text.visible = false

func _setze_fehlermeldung(msg: String):
	titel_label.text = "❌ Fehler"
	autor_label.text = ""
	sprache_label.text = ""
	fortschrittsbalken.value = 0
	fortschrittsbalken.text = "0%"
	seiten_label.text = ""
	status_label.text = msg
	highlights_label.text = ""
	notizen_label.text = ""
	hervorhebung_text.visible = false

func _on_neuladen_pressed():
	lade_metadaten()
