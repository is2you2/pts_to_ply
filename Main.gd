extends Control


func _ready():
	get_tree().connect("files_dropped", self, 'drag_drop')

const form:= [
	'ply',
	'format ascii 1.0',
	'element vertex %s',
	'property float x',
	'property float y',
	'property float z',
	'property uchar intensity',
	'property uchar red',
	'property uchar green',
	'property uchar blue',
	'end_header',
]

func drag_drop(files:PoolStringArray, scr):
	var _path:String
	for f in files:
		if f.find('.pts') + 1:
			_path = f
			break
	var file:= File.new()
	var result:= File.new()
	var err:= file.open(_path, File.READ)
	var rerr:= result.open(OS.get_executable_path() + '_result.ply', File.WRITE)
	var get_tree:= get_tree()
	if rerr != OK:
		get_tree.quit()
	file.seek_end()
	$maximum.text = str(file.get_position())
	file.seek(0)
	var f_line:= file.get_line()
	for line in form: # 양식 먼저 쓰기
		if line.find('%s') + 1:
			result.store_line(line % f_line)
		else:
			result.store_line(line)
	var count:= 0
	while not file.eof_reached():
		f_line = file.get_line()
		if not f_line:
			break
		result.store_line(f_line)
		$current.text = str(file.get_position())
		count += 1
		if count >= BUNDLE_COUNT:
			count = 0
			yield(get_tree, "physics_frame")
	result.flush()
	result.close()
	file.close()
	get_tree.quit()

# 한번에 처리하는 줄 수
const BUNDLE_COUNT:= 3000

func _exit_tree():
	get_tree().disconnect("files_dropped", self, 'drag_drop')
