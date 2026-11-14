extends RefCounted
## Reads data/c85_parts.json and turns it into catalog.gd sections, so main.gd only has to say
## what you have, what you can afford, and what to do when you buy.
##
## const PartsBook := preload("res://scripts/parts_book.gd")
## var book := PartsBook.new()                      # loads once
## book.no_for_fault("magneto")                     # -> "H4LN-21"
## book.sections(money, inventory, needed, buy_cb)  # -> [{id, tab, head, items}] for catalog.gd

const PATH := "res://data/c85_parts.json"

var engine := {}
var parts: Array = []
var by_id := {}
var by_fault := {}
var _sections: Array = []


func _init(path := PATH) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_warning("parts_book: can't open " + path)
		return
	var d = JSON.parse_string(f.get_as_text())
	if not d is Dictionary:
		return
	engine = d.get("engine", {})
	parts = d.get("parts", [])
	_sections = d.get("sections", [])
	for p in parts:
		by_id[p.id] = p
		if String(p.get("fault", "")) != "":
			by_fault[p.fault] = p


func no_for_fault(fault_id: String, fallback := "") -> String:
	return String(by_fault[fault_id].no) if by_fault.has(fault_id) else fallback


## Every part as catalog entries, one tab per section.
## inventory: part id or part name -> count. needed: part ids or names the current job still needs.
## buy_cb: Callable(part: Dictionary, price: int, mail: bool). mail_markup: 1.25 for mail order.
func sections(money: int, inventory: Dictionary, needed: Dictionary, buy_cb: Callable, mail := false, icons := {}) -> Array:
	var out := []
	for s in _sections:
		var items := []
		for p in parts:
			if p.section != s.id:
				continue
			var price := int(p.price * (1.25 if mail else 1.0))
			var icon: String = icons.get(p.id, String(p.get("icon", "")))
			if icon != "" and not ResourceLoader.exists(icon):
				icon = ""
			if icon == "" and ResourceLoader.exists("res://textures/catalog/%s.png" % p.id):
				icon = "res://textures/catalog/%s.png" % p.id
			items.append({"name": p.name, "no": p.no, "blurb": p.blurb, "icon": icon, "price": price, "mail": mail,
				"have": str(inventory.get(p.id, inventory.get(p.name, 0))), "needed": needed.has(p.id) or needed.has(p.name), "can": money >= price, "short": maxi(0, price - money),
				"buy": buy_cb.bind(p, price, mail)})
		items.sort_custom(func(a, b): return a.needed and not b.needed)
		out.append({"id": s.id, "tab": s.tab, "head": s.head, "items": items})
	return out


## Parts the manual lists for a job (oil_change, mag_timing, ...).
func for_job(job: String) -> Array:
	return parts.filter(func(p): return job in p.get("jobs", []))
