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
	get_tree().disconnect("files_dropped", self, 'drag_drop')
	var _path:String
	for f in files: # 파일 1개만 작업처리
		if f.find('.pts') + 1 or f.find('.ply') + 1:
			_path = f
			break
	var last_index:= _path.find_last('\\') + 1
	var _orig_dir_path:= _path.substr(0, last_index).replace('\\', '/')
	var _orig_filename:= _path.substr(last_index)
	var _orig_last_index:= _orig_filename.find_last('.')
	var _orig_name:= _orig_filename.substr(0, _orig_last_index)
	var _orig_ext:= _orig_filename.substr(_orig_last_index + 1)
	# UI 구성 받아오기
	var file:= File.new()
	var err:= file.open(_path, File.READ)
	var get_tree:= get_tree()
	file.seek_end()
	$ProgressBar.max_value = file.get_position()
	file.seek(0)
	$PercentSlider.editable = false
	$PercentEdit.editable = false
	$RedCol.editable = false
	$GreenCol.editable = false
	$BlueCol.editable = false
	var result:= File.new()
	var rerr:= result.open(_orig_dir_path + _orig_name + '_result.ply', File.WRITE)
	var total_vertex_count:int
	# 아래부터 파일 직접 편집
	if _orig_ext == 'pts': # 입력파일이 pts인경우 헤더처리 진행
		var count_line:= file.get_line()
		total_vertex_count = int(count_line)
		for line in form:
			if line.find('%s') + 1:
				result.store_line(line % count_line)
			else:
				result.store_line(line)
	if not total_vertex_count: # 총 vertex 수 책정하기
		for i in range(form.size()):
			var line:= file.get_csv_line(' ')
			if line[0] == 'element' and line[1] == 'vertex':
				total_vertex_count = int(line[2])
	return
	var work_count:= 0
	var f_line:String
	while not file.eof_reached():
		f_line = file.get_line()
		if not f_line:
			break
		result.store_line(f_line)
		$current.text = str(file.get_position())
		work_count += 1
		if work_count >= BUNDLE_COUNT:
			work_count = 0
			yield(get_tree, "physics_frame")
	result.flush()
	result.close()
	file.close()
	get_tree.quit()

# 한번에 처리하는 줄 수
const BUNDLE_COUNT:= 3000

func _on_LineEdit_text_changed(new_text):
	if new_text:
		$PercentSlider.value = float(new_text)
		$PercentSlider.editable = false
	else:
		$PercentSlider.editable = true

func _on_PercentSlider_value_changed(value):
	$PercentEdit.placeholder_text = str(value)
