extends Node

func _ready():
	# Pfad zur metadata.epub.lua Datei (absoluter Pfad)
	var metadata_datei = "/home/ts/Books/Nagel/WhatIsItLikeToBeABat/WhatIsItLikeToBeABat.sdr/metadata.epub.lua"
	
	# Falls die Datei im Projektverzeichnis liegt, z.B.:
	# var metadata_datei = "res://koreader/metadata.epub.lua"
	
	if not FileAccess.file_exists(metadata_datei):
		print("❌ Datei nicht gefunden: ", metadata_datei)
		return
	
	var lua = LuaState.new()
	lua.open_libraries()
	
	var lua_code = """
        local metadata = dofile("%s")
        return metadata
	""" % metadata_datei
	
	var ergebnis = lua.do_string(lua_code)
	
	if ergebnis == null:
		print("❌ Fehler beim Laden der Metadaten")
		return
	
	if ergebnis is LuaTable:
		print("✅ Metadaten erfolgreich geladen!")
		_metadaten_auswerten(ergebnis)
	else:
		print("❌ Unerwarteter Rückgabetyp: ", typeof(ergebnis))

func _metadaten_auswerten(metadata: LuaTable):
	print("\n" + "=".repeat(60))
	print("📚 METADATEN AUS KOREADER")
	print("=".repeat(60))
	
	# 1. Buchinformationen aus doc_props
	var doc_props = metadata.get("doc_props")
	if doc_props is LuaTable:
		var titel = doc_props.get("title", "Unbekannter Titel")
		var autor = doc_props.get("authors", "Unbekannter Autor")
		var sprache = doc_props.get("language", "Unbekannt")
		print("📖 Titel:    ", titel)
		print("✍️  Autor:    ", autor)
		print("🌐 Sprache:  ", sprache)
	
	# 2. Lese-Fortschritt
	var percent = metadata.get("percent_finished", 0.0)
	var prozent = round(percent * 100)
	print("📊 Fortschritt: ", prozent, "%")
	
	# 3. Seitenanzahl
	var doc_pages = metadata.get("doc_pages", 0)
	print("📄 Seiten:     ", doc_pages)
	
	# 4. Letzte gelesene Position
	var last_xpointer = metadata.get("last_xpointer", "")
	if last_xpointer != "":
		print("📍 Letzte Position: ", last_xpointer)
	
	# 5. Lese-Status
	var summary = metadata.get("summary")
	if summary is LuaTable:
		var status = summary.get("status", "unbekannt")
		var modified = summary.get("modified", "")
		print("📌 Status:     ", status)
		if modified != "":
			print("📅 Geändert:   ", modified)
	
	# 6. Annotationen (Hervorhebungen) – Anzahl aus stats.highlights
	var stats = metadata.get("stats")
	if stats is LuaTable:
		var highlights = stats.get("highlights", 0)
		var notes = stats.get("notes", 0)
		print("🖍️  Hervorhebungen: ", highlights)
		print("📝 Notizen:        ", notes)
		
		# Wenn Hervorhebungen existieren, die erste anzeigen (optional)
		if highlights > 0:
			var annotations = metadata.get("annotations")
			if annotations is LuaTable:
				var erste = annotations.get(1)
				if erste is LuaTable:
					var text = erste.get("text", "")
					var seite = erste.get("pageno", 0)
					var farbe = erste.get("color", "")
					print("\n✏️  Erste Hervorhebung (Seite ", seite, "):")
					print("   ", text.substr(0, 80), "…")
					print("   Farbe: ", farbe)
	
	# 7. Font-Einstellungen
	var font = metadata.get("font_face", "Standard")
	var font_size = metadata.get("copt_font_size", 0)
	print("\n🔤 Schriftart: ", font)
	print("🔠 Schriftgröße: ", font_size)
	
	print("\n" + "=".repeat(60))
