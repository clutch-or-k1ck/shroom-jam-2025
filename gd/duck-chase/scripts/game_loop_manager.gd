extends Node
class_name GameLoopManager

# the sequence is an array containing methods to execute. if a pause is needed, use a callable returning a signal
var sequence: Array
# what member of the sequence we are currently executing
var _idx := 0
var idx: int:
	set(idx):
		_idx = idx
		if _idx >= sequence.size() and looping:
			reset()
	get():
		return _idx
		
# we are currently waiting, and this variable represents the wait request
var _wait_request: WaitRequest = null
# when this game loop manager is currently playing its game loop
var playing: bool
# replay the sequence once it's finished
var looping: bool = true


class WaitRequest:
	var wait_for: float
	var accumulator: float
	
	func _init(wait_for: float):
		self.wait_for = wait_for
		self.accumulator = 0.
		
	func accumulate(delta: float) -> void:
		self.accumulator += delta
		
	func is_ready() -> bool:
		return self.accumulator >= wait_for
		
	func reset() -> void:
		accumulator = 0.


## returns a new wait request
static func wait(secs: float):
	return WaitRequest.new(secs)


## initialize with a sequence of events to replay. the sequence contains timestamps and procedures to launch at the timestamp
func _init(events: Dictionary):
	# NOTE this class was designed with 'sequence as Array' in mind - so convert the dictionary
	
	var timestamps := events.keys()
	timestamps.sort()
	
	for i in range(timestamps.size()):
		var timestamp = timestamps[i]
		if i == 0:
			sequence.append(self.wait(timestamps[i]))
		else:
			sequence.append(self.wait(timestamps[i] - timestamps[i - 1]))
			
		var event = events[timestamps[i]]
		if event is Callable:
			sequence.append(event)
		elif event is Array: # a number of events to call
			sequence.append_array(event)


func _exec_next():
	if idx >= sequence.size():
		return
	
	var next = sequence[idx]
	if next is Callable:
		next.call()
	elif next is WaitRequest:
		_wait_request = next
	idx += 1


func _process(delta: float) -> void:
	if playing:
		if _wait_request != null:
			_wait_request.accumulate(delta)
			if _wait_request.is_ready():
				_wait_request = null
				_exec_next()
		else:
			_exec_next()


func reset() -> void:
	_idx = 0
	for thing in sequence:
		if thing is WaitRequest:
			thing.reset()
			
