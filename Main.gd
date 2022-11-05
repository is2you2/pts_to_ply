extends Control


func _ready():
	get_tree().connect("files_dropped", self, 'drag_drop')
	$PercentEdit.placeholder_text = str($PercentSlider.value)
	$PercentEdit2.placeholder_text = str($PercentSlider2.value)

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
	$PercentSlider2.editable = false
	$PercentEdit.editable = false
	$PercentEdit2.editable = false
	$RedCol.editable = false
	$GreenCol.editable = false
	$BlueCol.editable = false
	var result:= File.new()
	var rerr:= result.open(_orig_dir_path + _orig_name + '_result.ply', File.WRITE)
	var total_vertex_count:int
	# 아래부터 파일 직접 편집, 헤더 부분
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
			result.store_csv_line(line, ' ')
	# 클라우드 포인트 부분
	var work_count:= 0 # 현재 작업량
	# 색상 초과 제한
	var color_limit:= {
		'red': 256,
		'green': 256,
		'blue': 256,
	}
	if $RedCol.text:
		color_limit['red'] = int($RedCol.text)
	if $GreenCol.text:
		color_limit['green'] = int($GreenCol.text)
	if $BlueCol.text:
		color_limit['blue'] = int($BlueCol.text)
	var line:Array
	var ratio:= 0.0
	var last_ratio_hundred:= 0
	while not file.eof_reached():
		line = file.get_csv_line(' ')
		$ProgressBar.value = file.get_position()
		if not line: break
		# 밀도에 따라 클라우드 무시
		ratio += density_ratio
		if ratio > 1000: ratio -= 1000
		var ratio_hundred:= int(ratio / 100)
		if last_ratio_hundred == ratio_hundred:
			total_vertex_count -= 1
			work_count += 1
			if work_count >= work_limit:
				work_count = 0
				yield(get_tree, "idle_frame")
			continue
		last_ratio_hundred = ratio_hundred
		# 색상 제한에 따라 클라우드 무시
		if line.size() == 7:
			if int(line[4]) <= color_limit['red'] and int(line[5]) <= color_limit['green'] and int(line[6]) <= color_limit['blue']:
				result.store_csv_line(line, ' ')
			else:
				total_vertex_count -= 1
		work_count += 1
		if work_count >= work_limit:
			work_count = 0
			yield(get_tree, "idle_frame")
	result.flush()
	file.close()
	result.seek(0)
	for i in range(11):
		var reline:= result.get_csv_line(' ')
		if reline[0] == 'element' and reline[1] == 'vertex':
			var _form:= 'element vertex %s' % str('%-',str(total_vertex_count).length(),'d')
			result.store_string(_form % total_vertex_count)
			break
	result.close()
	get_tree.quit()

# 한번에 처리하는 줄 수
var work_limit:= 2500
var density_ratio:= 100.0

func _on_LineEdit_text_changed(new_text):
	if new_text:
		$PercentSlider.value = float(new_text)
	$PercentSlider.editable = not bool(new_text)
	density_ratio = float(new_text)

func _on_PercentSlider_value_changed(value):
	$PercentEdit.placeholder_text = str(value)
	density_ratio = float(value)

func _on_PercentEdit2_text_changed(new_text):
	if new_text:
		$PercentSlider2.value = int(new_text)
	$PercentSlider2.editable = not bool(new_text)
	work_limit = int(new_text)

func _on_PercentSlider2_value_changed(value):
	$PercentEdit2.placeholder_text = str(value)
	work_limit = int(value)
	
