extends RefCounted
class_name SoftPLC

## IEC 61131-3 Instruction List (IL) / Ladder Soft-PLC Engine.
## Supports %IX, %QX, %MX, %IW, %QW, %MW, Timers (TON/TOF), Counters (CTU/CTD/RST),
## Edge detection (LDP/LDF/ANDP/ANDF/ORP/ORF), Branches (AND(/OR(/)), and Comparators.

const MAX_BITS := 256
const MAX_WORDS := 64
const MAX_TIMERS := 32
const MAX_COUNTERS := 32

var enabled: bool = false
var source_code: String = ""
var compiled_ops: Array[Dictionary] = []
var compile_errors: Array[String] = []

var memory_bits: Array[bool] = []
var memory_words: Array[int] = []
var _prev_bits: Dictionary = {}

# Timers: { "pt_ms": int, "et_ms": float, "q": bool, "last_in": bool }
var timers: Array[Dictionary] = []
# Counters: { "pv": int, "cv": int, "q": bool, "last_in": bool }
var counters: Array[Dictionary] = []

var scan_count: int = 0


func _init() -> void:
	memory_bits.resize(MAX_BITS)
	memory_bits.fill(false)
	memory_words.resize(MAX_WORDS)
	memory_words.fill(0)
	reset_runtime()


func reset_runtime() -> void:
	memory_bits.fill(false)
	memory_words.fill(0)
	_prev_bits.clear()
	timers.clear()
	for i in range(MAX_TIMERS):
		timers.append({"pt_ms": 1000, "et_ms": 0.0, "q": false, "last_in": false})
	counters.clear()
	for i in range(MAX_COUNTERS):
		counters.append({"pv": 1, "cv": 0, "q": false, "last_in": false})
	scan_count = 0


func compile(code: String) -> Dictionary:
	source_code = code
	compiled_ops.clear()
	compile_errors.clear()

	var paren_depth := 0
	var lines := code.split("\n")
	for idx in range(lines.size()):
		var line_num := idx + 1
		var raw := _strip_comments(lines[idx]).strip_edges()
		if raw.is_empty():
			continue

		var tokens := _tokenize(raw)
		if tokens.is_empty():
			continue

		var op := tokens[0].to_upper()
		if op == "END":
			break

		if op in ["MPS", "MRD", "MPP"]:
			compiled_ops.append({"op": op, "line": line_num})
			continue

		if op == ")":
			if paren_depth <= 0:
				compile_errors.append("Line %d: Unexpected ')'" % line_num)
				continue
			paren_depth -= 1
			compiled_ops.append({"op": ")", "line": line_num})
			continue

		if op in ["AND(", "OR("]:
			paren_depth += 1
			compiled_ops.append({"op": op, "line": line_num})
			continue

		const FX_BIT_ALIASES := {"LDI": "LDN", "ANI": "ANDN", "ORI": "ORN"}
		if FX_BIT_ALIASES.has(op):
			op = FX_BIT_ALIASES[op]

		if op in ["LD", "LDN", "LDP", "LDF", "AND", "ANDN", "ANDP", "ANDF", "OR", "ORN", "ORP", "ORF"]:
			if tokens.size() < 2:
				compile_errors.append("Line %d: '%s' requires a bit operand" % [line_num, op])
				continue
			var addr := _parse_bit_ref(tokens[1])
			if addr.is_empty():
				compile_errors.append("Line %d: Invalid bit address '%s'" % [line_num, tokens[1]])
				continue
			compiled_ops.append({"op": op, "ref": addr, "line": line_num})
			continue

		if op == "OUT":
			if tokens.size() < 2:
				compile_errors.append("Line %d: 'OUT' requires target (Y0, M0, T0 K20, C0 K5)" % line_num)
				continue
			var t_idx := _parse_fb_index(tokens[1], "T", MAX_TIMERS)
			if t_idx >= 0:
				if tokens.size() < 3:
					compile_errors.append("Line %d: 'OUT %s' requires preset (e.g. K20 or 2.0s)" % [line_num, tokens[1]])
					continue
				var pt_ms := _parse_fx_time_ms(tokens[2])
				if pt_ms < 0:
					compile_errors.append("Line %d: Invalid timer preset '%s'" % [line_num, tokens[2]])
					continue
				compiled_ops.append({"op": "TON", "idx": t_idx, "pt_ms": pt_ms, "line": line_num})
				continue
			var c_idx := _parse_fb_index(tokens[1], "C", MAX_COUNTERS)
			if c_idx >= 0:
				if tokens.size() < 3:
					compile_errors.append("Line %d: 'OUT %s' requires preset (e.g. K5)" % [line_num, tokens[1]])
					continue
				var pv := _parse_fx_count(tokens[2])
				if pv < 0:
					compile_errors.append("Line %d: Invalid counter preset '%s'" % [line_num, tokens[2]])
					continue
				compiled_ops.append({"op": "CTU", "idx": c_idx, "pv": pv, "line": line_num})
				continue
			var out_addr := _parse_bit_ref(tokens[1])
			if out_addr.is_empty() or out_addr["area"] not in ["Q", "M"]:
				compile_errors.append("Line %d: 'OUT' target must be Y/M/%%QX/%%MX (got '%s')" % [line_num, tokens[1]])
				continue
			compiled_ops.append({"op": "ST", "ref": out_addr, "line": line_num})
			continue

		if op == "SET":
			op = "S"

		if op in ["ST", "STN", "S", "R", "PLS", "PLF"]:
			if tokens.size() < 2:
				compile_errors.append("Line %d: '%s' requires an output bit (Y/M/%%QX/%%MX)" % [line_num, op])
				continue
			var addr := _parse_bit_ref(tokens[1])
			if addr.is_empty() or addr["area"] not in ["Q", "M"]:
				compile_errors.append("Line %d: '%s' target must be Y/M/%%QX/%%MX (got '%s')" % [line_num, op, tokens[1]])
				continue
			compiled_ops.append({"op": op, "ref": addr, "line": line_num})
			continue

		if op == "MOV":
			if tokens.size() < 3:
				compile_errors.append("Line %d: 'MOV' requires source & destination (e.g. MOV K10 D0)" % line_num)
				continue
			var src := _parse_word_ref(tokens[1])
			var dst := _parse_word_ref(tokens[2])
			if src.is_empty() or dst.is_empty() or dst["area"] not in ["QW", "MW"]:
				compile_errors.append("Line %d: Invalid MOV operand in '%s'" % [line_num, raw])
				continue
			compiled_ops.append({"op": "MOV", "src": src, "dst": dst, "line": line_num})
			continue

		if op in ["TON", "TOF"]:
			if tokens.size() < 3:
				compile_errors.append("Line %d: '%s' requires Timer & PT (e.g. TON T0 2000ms)" % [line_num, op])
				continue
			var t_idx := _parse_fb_index(tokens[1], "T", MAX_TIMERS)
			if t_idx < 0:
				compile_errors.append("Line %d: Invalid timer '%s' (use T0..T%d)" % [line_num, tokens[1], MAX_TIMERS - 1])
				continue
			var pt_ms := _parse_time_ms(tokens[2])
			if pt_ms < 0:
				compile_errors.append("Line %d: Invalid preset time '%s' (use e.g. 2000ms or 2.0s)" % [line_num, tokens[2]])
				continue
			compiled_ops.append({"op": op, "idx": t_idx, "pt_ms": pt_ms, "line": line_num})
			continue

		if op in ["CTU", "CTD"]:
			if tokens.size() < 3:
				compile_errors.append("Line %d: '%s' requires Counter & PV (e.g. CTU C0 5)" % [line_num, op])
				continue
			var c_idx := _parse_fb_index(tokens[1], "C", MAX_COUNTERS)
			if c_idx < 0:
				compile_errors.append("Line %d: Invalid counter '%s' (use C0..C%d)" % [line_num, tokens[1], MAX_COUNTERS - 1])
				continue
			var pv := _parse_int_or_kv(tokens[2], "PV")
			if pv < 0:
				compile_errors.append("Line %d: Invalid preset value '%s'" % [line_num, tokens[2]])
				continue
			compiled_ops.append({"op": op, "idx": c_idx, "pv": pv, "line": line_num})
			continue

		if op == "RST":
			if tokens.size() < 2:
				compile_errors.append("Line %d: 'RST' requires T0.. or C0.. or %%MX/%%QX" % line_num)
				continue
			var t_idx := _parse_fb_index(tokens[1], "T", MAX_TIMERS)
			if t_idx >= 0:
				compiled_ops.append({"op": "RST_T", "idx": t_idx, "line": line_num})
				continue
			var c_idx := _parse_fb_index(tokens[1], "C", MAX_COUNTERS)
			if c_idx >= 0:
				compiled_ops.append({"op": "RST_C", "idx": c_idx, "line": line_num})
				continue
			var addr := _parse_bit_ref(tokens[1])
			if not addr.is_empty() and addr["area"] in ["Q", "M"]:
				compiled_ops.append({"op": "R", "ref": addr, "line": line_num})
				continue
			compile_errors.append("Line %d: Invalid RST target '%s'" % [line_num, tokens[1]])
			continue

		var cmp_info := _parse_comparator_op(op)
		if not cmp_info.is_empty():
			if tokens.size() < 3:
				compile_errors.append("Line %d: '%s' requires 2 operands (e.g. %s %%IW0 50)" % [line_num, op, op])
				continue
			var lhs := _parse_word_ref(tokens[1])
			var rhs := _parse_word_ref(tokens[2])
			if lhs.is_empty() or rhs.is_empty():
				compile_errors.append("Line %d: Invalid word operand in '%s'" % [line_num, raw])
				continue
			compiled_ops.append({
				"op": "CMP",
				"comb": cmp_info["comb"],
				"cmp": cmp_info["cmp"],
				"lhs": lhs,
				"rhs": rhs,
				"line": line_num,
			})
			continue

		compile_errors.append("Line %d: Unknown instruction '%s'" % [line_num, op])

	if paren_depth > 0:
		compile_errors.append("Unclosed '(' (%d missing ')')" % paren_depth)

	return {
		"ok": compile_errors.is_empty(),
		"errors": compile_errors.duplicate(),
		"instruction_count": compiled_ops.size(),
	}


func step(delta: float, mb: Node) -> void:
	if not enabled or compiled_ops.is_empty() or mb == null:
		return
	scan_count += 1
	var dt_ms := delta * 1000.0
	var cr: bool = false
	var stack: Array[Dictionary] = []
	var fx_stack: Array[bool] = []
	var rung_start: bool = true

	for ins_idx in range(compiled_ops.size()):
		var ins: Dictionary = compiled_ops[ins_idx]
		var op: String = ins["op"]
		match op:
			"MPS":
				fx_stack.append(cr)
			"MRD":
				if not fx_stack.is_empty():
					cr = fx_stack[fx_stack.size() - 1]
			"MPP":
				if not fx_stack.is_empty():
					cr = fx_stack.pop_back()
			"AND(", "OR(":
				stack.append({"comb": "AND" if op == "AND(" else "OR", "cr": cr})
				rung_start = true
			")":
				if not stack.is_empty():
					var frame: Dictionary = stack.pop_back()
					var prev_cr: bool = frame["cr"]
					cr = (prev_cr and cr) if frame["comb"] == "AND" else (prev_cr or cr)
				rung_start = false
			"LD":
				cr = _read_bit(ins["ref"], mb)
				rung_start = false
			"LDN":
				cr = not _read_bit(ins["ref"], mb)
				rung_start = false
			"LDP":
				cr = _read_edge(ins_idx, ins["ref"], mb, true)
				rung_start = false
			"LDF":
				cr = _read_edge(ins_idx, ins["ref"], mb, false)
				rung_start = false
			"AND":
				cr = cr and _read_bit(ins["ref"], mb)
				rung_start = false
			"ANDN":
				cr = cr and (not _read_bit(ins["ref"], mb))
				rung_start = false
			"ANDP":
				cr = cr and _read_edge(ins_idx, ins["ref"], mb, true)
				rung_start = false
			"ANDF":
				cr = cr and _read_edge(ins_idx, ins["ref"], mb, false)
				rung_start = false
			"OR":
				cr = cr or _read_bit(ins["ref"], mb)
				rung_start = false
			"ORN":
				cr = cr or (not _read_bit(ins["ref"], mb))
				rung_start = false
			"ORP":
				cr = cr or _read_edge(ins_idx, ins["ref"], mb, true)
				rung_start = false
			"ORF":
				cr = cr or _read_edge(ins_idx, ins["ref"], mb, false)
				rung_start = false
			"CMP":
				var lhs_v := _read_word(ins["lhs"], mb)
				var rhs_v := _read_word(ins["rhs"], mb)
				var res := _eval_cmp(ins["cmp"], lhs_v, rhs_v)
				var comb: String = ins["comb"]
				if comb == "LD" or (comb == "AUTO" and rung_start):
					cr = res
				elif comb == "OR":
					cr = cr or res
				else:
					cr = cr and res
				rung_start = false
			"TON":
				var t_idx: int = ins["idx"]
				var pt: int = ins["pt_ms"]
				var t: Dictionary = timers[t_idx]
				t["pt_ms"] = pt
				if cr:
					t["et_ms"] = minf(float(t["et_ms"]) + dt_ms, float(pt))
					t["q"] = float(t["et_ms"]) >= float(pt)
				else:
					t["et_ms"] = 0.0
					t["q"] = false
				t["last_in"] = cr
				cr = bool(t["q"])
				rung_start = false
			"TOF":
				var t_idx: int = ins["idx"]
				var pt: int = ins["pt_ms"]
				var t: Dictionary = timers[t_idx]
				t["pt_ms"] = pt
				if cr:
					t["et_ms"] = 0.0
					t["q"] = true
				else:
					if bool(t["q"]):
						t["et_ms"] = minf(float(t["et_ms"]) + dt_ms, float(pt))
						if float(t["et_ms"]) >= float(pt):
							t["q"] = false
				t["last_in"] = cr
				cr = bool(t["q"])
				rung_start = false
			"CTU":
				var c_idx: int = ins["idx"]
				var pv: int = ins["pv"]
				var c: Dictionary = counters[c_idx]
				c["pv"] = pv
				if cr and not bool(c["last_in"]):
					c["cv"] = int(c["cv"]) + 1
				c["last_in"] = cr
				c["q"] = int(c["cv"]) >= pv
				cr = bool(c["q"])
				rung_start = false
			"CTD":
				var c_idx: int = ins["idx"]
				var pv: int = ins["pv"]
				var c: Dictionary = counters[c_idx]
				c["pv"] = pv
				if cr and not bool(c["last_in"]):
					c["cv"] = maxi(0, int(c["cv"]) - 1)
				c["last_in"] = cr
				c["q"] = int(c["cv"]) <= 0
				cr = bool(c["q"])
				rung_start = false
			"RST_T":
				if cr:
					var t: Dictionary = timers[ins["idx"]]
					t["et_ms"] = 0.0
					t["q"] = false
				rung_start = true
			"RST_C":
				if cr:
					var c: Dictionary = counters[ins["idx"]]
					c["cv"] = 0
					c["q"] = false
				rung_start = true
			"ST":
				_write_bit(ins["ref"], cr, mb)
				rung_start = true
			"STN":
				_write_bit(ins["ref"], not cr, mb)
				rung_start = true
			"S":
				if cr:
					_write_bit(ins["ref"], true, mb)
				rung_start = true
			"R":
				if cr:
					_write_bit(ins["ref"], false, mb)
				rung_start = true
			"PLS", "PLF":
				var pkey := "p_%d" % ins_idx
				var prev := bool(_prev_bits.get(pkey, false))
				_prev_bits[pkey] = cr
				var trig := (cr and not prev) if op == "PLS" else (not cr and prev)
				_write_bit(ins["ref"], trig, mb)
				rung_start = true
			"MOV":
				if cr:
					_write_word(ins["dst"], _read_word(ins["src"], mb), mb)
				rung_start = true


func _strip_comments(line: String) -> String:
	var out := line
	for marker in ["//", ";", "#"]:
		var pos := out.find(marker)
		if pos >= 0:
			out = out.substr(0, pos)
	var b_start := out.find("(*")
	if b_start >= 0:
		var b_end := out.find("*)", b_start + 2)
		if b_end >= 0:
			out = out.substr(0, b_start) + " " + out.substr(b_end + 2)
		else:
			out = out.substr(0, b_start)
	return out


func _tokenize(line: String) -> Array[String]:
	var cleaned := line.replace(",", " ")
	var raw_parts := cleaned.split(" ", false)
	var out: Array[String] = []
	for p in raw_parts:
		var s := p.strip_edges()
		if not s.is_empty():
			out.append(s)
	return out


func _parse_octal(s: String) -> int:
	if s.is_empty():
		return -1
	var val := 0
	for i in range(s.length()):
		var code := s.unicode_at(i)
		if code < 48 or code > 55:
			return -1
		val = val * 8 + (code - 48)
	return val


func _parse_bit_ref(token: String) -> Dictionary:
	var s := token.strip_edges().to_upper()
	if s.begins_with("T"):
		var t_str := s.substr(1)
		if t_str.ends_with(".Q"):
			t_str = t_str.substr(0, t_str.length() - 2)
		if t_str.is_valid_int():
			var idx := t_str.to_int()
			if idx >= 0 and idx < MAX_TIMERS:
				return {"area": "T", "idx": idx}
		return {}
	if s.begins_with("C"):
		var c_str := s.substr(1)
		if c_str.ends_with(".Q"):
			c_str = c_str.substr(0, c_str.length() - 2)
		if c_str.is_valid_int():
			var idx := c_str.to_int()
			if idx >= 0 and idx < MAX_COUNTERS:
				return {"area": "C", "idx": idx}
		return {}
	if s.begins_with("X") and not s.contains("."):
		var x_idx := _parse_octal(s.substr(1))
		if x_idx >= 0 and x_idx < MAX_BITS:
			return {"area": "I", "idx": x_idx}
		return {}
	if s.begins_with("Y") and not s.contains("."):
		var y_idx := _parse_octal(s.substr(1))
		if y_idx >= 0 and y_idx < MAX_BITS:
			return {"area": "Q", "idx": y_idx}
		return {}
	if s.begins_with("%"):
		s = s.substr(1)
	var area := ""
	if s.begins_with("IX") or s.begins_with("QX") or s.begins_with("MX"):
		area = s.substr(0, 1)
		s = s.substr(2)
	elif s.begins_with("I") or s.begins_with("Q") or s.begins_with("M"):
		area = s.substr(0, 1)
		s = s.substr(1)
	else:
		return {}
	if s.is_valid_int():
		var idx := s.to_int()
		if idx >= 0 and idx < MAX_BITS:
			return {"area": area, "idx": idx}
		return {}
	var parts := s.split(".")
	if parts.size() == 2 and parts[0].is_valid_int() and parts[1].is_valid_int():
		var b := parts[0].to_int()
		var bit := parts[1].to_int()
		if b >= 0 and bit >= 0 and bit <= 7:
			var idx := b * 8 + bit
			if idx < MAX_BITS:
				return {"area": area, "idx": idx}
	return {}


func _parse_word_ref(token: String) -> Dictionary:
	var s := token.strip_edges().to_upper()
	if s.is_valid_int():
		return {"area": "CONST", "val": s.to_int()}
	if s.begins_with("K") and s.substr(1).is_valid_int():
		return {"area": "CONST", "val": s.substr(1).to_int()}
	if s.begins_with("H") and s.length() > 1 and ("0x" + s.substr(1)).is_valid_hex_number(true):
		return {"area": "CONST", "val": ("0x" + s.substr(1)).hex_to_int()}
	if s.begins_with("D") and s.substr(1).is_valid_int():
		var d_idx := s.substr(1).to_int()
		if d_idx >= 0 and d_idx < MAX_WORDS:
			return {"area": "MW", "idx": d_idx}
	if s.begins_with("T") and s.ends_with(".ET"):
		var t_str := s.substr(1, s.length() - 4)
		if t_str.is_valid_int() and t_str.to_int() >= 0 and t_str.to_int() < MAX_TIMERS:
			return {"area": "TET", "idx": t_str.to_int()}
	if s.begins_with("C") and s.ends_with(".CV"):
		var c_str := s.substr(1, s.length() - 4)
		if c_str.is_valid_int() and c_str.to_int() >= 0 and c_str.to_int() < MAX_COUNTERS:
			return {"area": "CCV", "idx": c_str.to_int()}
	if s.begins_with("%"):
		s = s.substr(1)
	if s.begins_with("IW"):
		var idx_str := s.substr(2)
		if idx_str.is_valid_int() and idx_str.to_int() >= 0 and idx_str.to_int() < MAX_BITS:
			return {"area": "IW", "idx": idx_str.to_int()}
	elif s.begins_with("QW"):
		var idx_str := s.substr(2)
		if idx_str.is_valid_int() and idx_str.to_int() >= 0 and idx_str.to_int() < MAX_BITS:
			return {"area": "QW", "idx": idx_str.to_int()}
	elif s.begins_with("MW"):
		var idx_str := s.substr(2)
		if idx_str.is_valid_int() and idx_str.to_int() >= 0 and idx_str.to_int() < MAX_WORDS:
			return {"area": "MW", "idx": idx_str.to_int()}
	return {}


func _parse_fb_index(token: String, prefix: String, limit: int) -> int:
	var s := token.strip_edges().to_upper()
	if s.begins_with(prefix):
		var num := s.substr(prefix.length())
		if num.is_valid_int():
			var idx := num.to_int()
			if idx >= 0 and idx < limit:
				return idx
	return -1


func _parse_time_ms(token: String) -> int:
	var s := token.strip_edges().to_upper()
	if s.begins_with("PT:="):
		s = s.substr(4)
	elif s.begins_with("T#"):
		s = s.substr(2)
	if s.ends_with("MS"):
		var num := s.substr(0, s.length() - 2)
		if num.is_valid_float():
			return maxi(0, roundi(num.to_float()))
	elif s.ends_with("S"):
		var num := s.substr(0, s.length() - 1)
		if num.is_valid_float():
			return maxi(0, roundi(num.to_float() * 1000.0))
	elif s.is_valid_int():
		return maxi(0, s.to_int())
	return -1


func _parse_int_or_kv(token: String, key: String) -> int:
	var s := token.strip_edges().to_upper()
	if s.begins_with(key + ":="):
		s = s.substr(key.length() + 2)
	if s.is_valid_int():
		return s.to_int()
	return -1


func _parse_fx_time_ms(token: String) -> int:
	var s := token.strip_edges().to_upper()
	if s.begins_with("K") and s.substr(1).is_valid_int():
		return maxi(0, s.substr(1).to_int() * 100)
	return _parse_time_ms(token)


func _parse_fx_count(token: String) -> int:
	var s := token.strip_edges().to_upper()
	if s.begins_with("K") and s.substr(1).is_valid_int():
		return s.substr(1).to_int()
	return _parse_int_or_kv(token, "PV")


func _parse_comparator_op(op: String) -> Dictionary:
	var cmps := ["EQ", "NE", "GT", "GE", "LT", "LE"]
	const FX_CMP_MAP := {
		"=": "EQ",
		"<>": "NE",
		">": "GT",
		">=": "GE",
		"<": "LT",
		"<=": "LE",
	}
	if op in cmps:
		return {"comb": "AUTO", "cmp": op}
	for prefix in ["LD_", "AND_", "OR_"]:
		if op.begins_with(prefix):
			var suffix := op.substr(prefix.length())
			if suffix in cmps:
				return {"comb": prefix.trim_suffix("_"), "cmp": suffix}
	for prefix in ["LD", "AND", "OR"]:
		if op.begins_with(prefix):
			var sym := op.substr(prefix.length())
			if FX_CMP_MAP.has(sym):
				return {"comb": prefix, "cmp": FX_CMP_MAP[sym]}
	return {}


func _read_bit(ref: Dictionary, mb: Node) -> bool:
	var area: String = ref["area"]
	var idx: int = ref["idx"]
	match area:
		"I":
			return bool(mb.call("get_discrete_input", idx))
		"Q":
			return bool(mb.call("get_coil", idx))
		"M":
			return memory_bits[idx]
		"T":
			return bool(timers[idx]["q"])
		"C":
			return bool(counters[idx]["q"])
	return false


func _read_edge(ins_idx: int, ref: Dictionary, mb: Node, rising: bool) -> bool:
	var key := "%d_%s_%d" % [ins_idx, ref["area"], ref["idx"]]
	var cur := _read_bit(ref, mb)
	var prev := bool(_prev_bits.get(key, false))
	_prev_bits[key] = cur
	return (cur and not prev) if rising else (not cur and prev)


func _write_bit(ref: Dictionary, val: bool, mb: Node) -> void:
	var area: String = ref["area"]
	var idx: int = ref["idx"]
	if area == "Q":
		mb.call("set_coil", idx, val)
	elif area == "M":
		memory_bits[idx] = val


func _write_word(ref: Dictionary, val: int, mb: Node) -> void:
	var area: String = ref["area"]
	var idx: int = ref["idx"]
	if area == "QW":
		mb.call("set_holding_register", idx, val)
	elif area == "MW" and idx >= 0 and idx < MAX_WORDS:
		memory_words[idx] = val & 0xFFFF


func _read_word(ref: Dictionary, mb: Node) -> int:
	var area: String = ref["area"]
	match area:
		"CONST":
			return int(ref["val"])
		"IW":
			var ir: Array = mb.get("input_registers")
			var idx: int = ref["idx"]
			return int(ir[idx]) if idx >= 0 and idx < ir.size() else 0
		"QW":
			return int(mb.call("get_holding_register", ref["idx"]))
		"MW":
			return memory_words[ref["idx"]]
		"TET":
			return roundi(float(timers[ref["idx"]]["et_ms"]))
		"CCV":
			return int(counters[ref["idx"]]["cv"])
	return 0


func _eval_cmp(cmp: String, a: int, b: int) -> bool:
	match cmp:
		"EQ":
			return a == b
		"NE":
			return a != b
		"GT":
			return a > b
		"GE":
			return a >= b
		"LT":
			return a < b
		"LE":
			return a <= b
	return false
