extends Node
## Pure GDScript Modbus TCP Server (MBAP + FC01..FC06, FC15, FC16).
## Default port is 1502 (non-privileged on Linux); change `port` if running as root on 502.

const REGISTER_COUNT := 256

@export var port: int = 1502
@export var bind_address: String = "0.0.0.0"
@export var auto_start: bool = true

var _server := TCPServer.new()
var _clients: Array[StreamPeerTCP] = []
var _rx_buffers: Array[PackedByteArray] = []
var _listening := false

var coils: Array[bool] = []
var discrete_inputs: Array[bool] = []
var holding_registers: Array[int] = []
var input_registers: Array[int] = []

signal coil_written(address: int, value: bool)
signal holding_register_written(address: int, value: int)

func _ready() -> void:
	coils.resize(REGISTER_COUNT)
	coils.fill(false)
	discrete_inputs.resize(REGISTER_COUNT)
	discrete_inputs.fill(false)
	holding_registers.resize(REGISTER_COUNT)
	holding_registers.fill(0)
	input_registers.resize(REGISTER_COUNT)
	input_registers.fill(0)
	if auto_start:
		start_server()

func start_server() -> Error:
	if _listening:
		return OK
	var err := _server.listen(port, bind_address)
	if err == OK:
		_listening = true
	else:
		push_warning("ModbusTCP failed to listen on %s:%d (err=%d)" % [bind_address, port, err])
	return err

func stop_server() -> void:
	for client in _clients:
		client.disconnect_from_host()
	_clients.clear()
	_rx_buffers.clear()
	_server.stop()
	_listening = false

func is_listening() -> bool:
	return _listening

func client_count() -> int:
	return _clients.size()

func get_coil(address: int) -> bool:
	if address < 0 or address >= REGISTER_COUNT:
		return false
	return coils[address]

func set_coil(address: int, value: bool) -> void:
	if address >= 0 and address < REGISTER_COUNT:
		coils[address] = value

func get_discrete_input(address: int) -> bool:
	if address < 0 or address >= REGISTER_COUNT:
		return false
	return discrete_inputs[address]

func set_discrete_input(address: int, value: bool) -> void:
	if address >= 0 and address < REGISTER_COUNT:
		discrete_inputs[address] = value

func get_holding_register(address: int) -> int:
	if address < 0 or address >= REGISTER_COUNT:
		return 0
	return holding_registers[address]

func set_holding_register(address: int, value: int) -> void:
	if address >= 0 and address < REGISTER_COUNT:
		holding_registers[address] = value & 0xFFFF

func set_input_register(address: int, value: int) -> void:
	if address >= 0 and address < REGISTER_COUNT:
		input_registers[address] = value & 0xFFFF

func _process(_delta: float) -> void:
	if not _listening:
		return
	while _server.is_connection_available():
		var peer := _server.take_connection()
		if peer != null:
			peer.set_no_delay(true)
			_clients.append(peer)
			_rx_buffers.append(PackedByteArray())

	for i in range(_clients.size() - 1, -1, -1):
		var client := _clients[i]
		client.poll()
		var status := client.get_status()
		if status == StreamPeerTCP.STATUS_ERROR or status == StreamPeerTCP.STATUS_NONE:
			_clients.remove_at(i)
			_rx_buffers.remove_at(i)
			continue
		if status != StreamPeerTCP.STATUS_CONNECTED:
			continue
		var avail := client.get_available_bytes()
		if avail > 0:
			var chunk := client.get_data(avail)
			if chunk[0] == OK:
				_rx_buffers[i].append_array(chunk[1])
				_process_buffer(i)

func _process_buffer(idx: int) -> void:
	var buf := _rx_buffers[idx]
	while buf.size() >= 7:
		var length := (buf[4] << 8) | buf[5]
		var total_len := 6 + length
		if length < 2 or total_len > 260:
			buf.clear()
			break
		if buf.size() < total_len:
			break
		var frame := buf.slice(0, total_len)
		buf = buf.slice(total_len)
		var response := _handle_mbap_frame(frame)
		if not response.is_empty():
			_clients[idx].put_data(response)
	_rx_buffers[idx] = buf

func _handle_mbap_frame(frame: PackedByteArray) -> PackedByteArray:
	var tid_hi := frame[0]
	var tid_lo := frame[1]
	var proto := (frame[2] << 8) | frame[3]
	if proto != 0:
		return PackedByteArray()
	var unit_id := frame[6]
	var pdu := frame.slice(7)
	var resp_pdu := _handle_pdu(pdu)
	if resp_pdu.is_empty():
		return PackedByteArray()
	var mbap_len := 1 + resp_pdu.size()
	var out := PackedByteArray([tid_hi, tid_lo, 0, 0, (mbap_len >> 8) & 0xFF, mbap_len & 0xFF, unit_id])
	out.append_array(resp_pdu)
	return out

func _handle_pdu(pdu: PackedByteArray) -> PackedByteArray:
	if pdu.is_empty():
		return PackedByteArray()
	var fc := pdu[0]
	match fc:
		0x01: # Read Coils
			if pdu.size() < 5:
				return _exception(fc, 0x03)
			var start := (pdu[1] << 8) | pdu[2]
			var count := (pdu[3] << 8) | pdu[4]
			return _read_bits(fc, coils, start, count)
		0x02: # Read Discrete Inputs
			if pdu.size() < 5:
				return _exception(fc, 0x03)
			var start := (pdu[1] << 8) | pdu[2]
			var count := (pdu[3] << 8) | pdu[4]
			return _read_bits(fc, discrete_inputs, start, count)
		0x03: # Read Holding Registers
			if pdu.size() < 5:
				return _exception(fc, 0x03)
			var start := (pdu[1] << 8) | pdu[2]
			var count := (pdu[3] << 8) | pdu[4]
			return _read_registers(fc, holding_registers, start, count)
		0x04: # Read Input Registers
			if pdu.size() < 5:
				return _exception(fc, 0x03)
			var start := (pdu[1] << 8) | pdu[2]
			var count := (pdu[3] << 8) | pdu[4]
			return _read_registers(fc, input_registers, start, count)
		0x05: # Write Single Coil
			if pdu.size() < 5:
				return _exception(fc, 0x03)
			var addr := (pdu[1] << 8) | pdu[2]
			var val_word := (pdu[3] << 8) | pdu[4]
			if addr >= REGISTER_COUNT or (val_word != 0x0000 and val_word != 0xFF00):
				return _exception(fc, 0x02 if addr >= REGISTER_COUNT else 0x03)
			var state := val_word == 0xFF00
			coils[addr] = state
			coil_written.emit(addr, state)
			return pdu.slice(0, 5)
		0x06: # Write Single Register
			if pdu.size() < 5:
				return _exception(fc, 0x03)
			var addr := (pdu[1] << 8) | pdu[2]
			var val := (pdu[3] << 8) | pdu[4]
			if addr >= REGISTER_COUNT:
				return _exception(fc, 0x02)
			holding_registers[addr] = val
			holding_register_written.emit(addr, val)
			return pdu.slice(0, 5)
		0x0F: # Write Multiple Coils
			if pdu.size() < 6:
				return _exception(fc, 0x03)
			var start := (pdu[1] << 8) | pdu[2]
			var count := (pdu[3] << 8) | pdu[4]
			var byte_count := pdu[5]
			if count < 1 or start + count > REGISTER_COUNT or pdu.size() < 6 + byte_count:
				return _exception(fc, 0x02)
			for i in count:
				var state := ((pdu[6 + (i >> 3)] >> (i & 7)) & 1) == 1
				coils[start + i] = state
				coil_written.emit(start + i, state)
			return PackedByteArray([fc, pdu[1], pdu[2], pdu[3], pdu[4]])
		0x10: # Write Multiple Registers
			if pdu.size() < 6:
				return _exception(fc, 0x03)
			var start := (pdu[1] << 8) | pdu[2]
			var count := (pdu[3] << 8) | pdu[4]
			var byte_count := pdu[5]
			if count < 1 or start + count > REGISTER_COUNT or byte_count != count * 2 or pdu.size() < 6 + byte_count:
				return _exception(fc, 0x02)
			for i in count:
				var val := (pdu[6 + i * 2] << 8) | pdu[7 + i * 2]
				holding_registers[start + i] = val
				holding_register_written.emit(start + i, val)
			return PackedByteArray([fc, pdu[1], pdu[2], pdu[3], pdu[4]])
		_:
			return _exception(fc, 0x01)

func _read_bits(fc: int, table: Array[bool], start: int, count: int) -> PackedByteArray:
	if count < 1 or count > 2000 or start + count > REGISTER_COUNT:
		return _exception(fc, 0x02)
	var byte_count := (count + 7) >> 3
	var out := PackedByteArray([fc, byte_count])
	for b in byte_count:
		var byte_val := 0
		for bit in 8:
			var idx := start + b * 8 + bit
			if idx < start + count and table[idx]:
				byte_val |= (1 << bit)
		out.append(byte_val)
	return out

func _read_registers(fc: int, table: Array[int], start: int, count: int) -> PackedByteArray:
	if count < 1 or count > 125 or start + count > REGISTER_COUNT:
		return _exception(fc, 0x02)
	var out := PackedByteArray([fc, count * 2])
	for i in count:
		var val := table[start + i]
		out.append((val >> 8) & 0xFF)
		out.append(val & 0xFF)
	return out

func _exception(fc: int, code: int) -> PackedByteArray:
	return PackedByteArray([fc | 0x80, code])
