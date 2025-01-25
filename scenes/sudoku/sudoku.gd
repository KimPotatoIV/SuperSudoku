extends Node2D

##################################################
const num_0 = preload("res://scenes/sudoku/num_0.png")
const num_1 = preload("res://scenes/sudoku/num_1.png")
const num_2 = preload("res://scenes/sudoku/num_2.png")
const num_3 = preload("res://scenes/sudoku/num_3.png")
const num_4 = preload("res://scenes/sudoku/num_4.png")
const num_5 = preload("res://scenes/sudoku/num_5.png")
const num_6 = preload("res://scenes/sudoku/num_6.png")
const num_7 = preload("res://scenes/sudoku/num_7.png")
const num_8 = preload("res://scenes/sudoku/num_8.png")
const num_9 = preload("res://scenes/sudoku/num_9.png")
# 텍스처 미리 불러옴

const SUDOKU_WIDTH_SIZE = 9
# 한 변 길이
const SUDOKU_SIZE = SUDOKU_WIDTH_SIZE * SUDOKU_WIDTH_SIZE
# 전체 스도쿠 셀 개수
const OFFSET = 9
# 가장자리 선 굵기
const CELL_SIZE = 116
# 셀 하나 픽셀 크기

var sudoku_array = []
# 스도쿠 전체 배열
var row_array = []
# 행 별 배열. 행 유효성 검사에 쓰임
var column_array = []
# 열 별 배열. 열 유효성 검사에 쓰임
var box_array = []
# 9셀 박스 별 배열. 9셀 박스 유효성 검사에 쓰임

var record_array = []
# 스도쿠를 채우면서 이전 셀에 채웠던 숫자 저장에 쓰이는 배열
var index = 0
# 현재 연산 중인 셀

var success_to_generate: bool = false
# 스도쿠 채우기에 성공했는지 여부

var draw_timer: Timer
# 각 셀 연산 간격 타이머
var drawing: bool = false
# 스도쿠를 그리는 중인지 여부

var generate_audio_player
# 스도쿠 연산 중 재생 오디오

##################################################
func _ready() -> void:	
	init_sudoku()
	# 각 필요 데이터 초기화
	
	draw_timer = $DrawTimer
	draw_timer.wait_time = 0.05
	draw_timer.one_shot = true
	draw_timer.connect("timeout", Callable(self, "_on_draw_timer_timeout"))
	# draw_timer 초기화
	
	generate_audio_player = $GenerateAudioPlayer
	# generate_audio_player 초기화

##################################################
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept") and not drawing:
		drawing = true
		draw_timer.start()
		
		generate_sudoku()
		draw_sudoku()
	# 스페이스를 누르면 스도쿠 연산과 함께 그리며 채우기 시작
	
	if Input.is_action_just_pressed("ui_cancel") and success_to_generate:
		erase_random_numbers()
	# esc를 누르면 완성 된 스도쿠에서 셀을 10개씩 삭제

##################################################
func init_sudoku() -> void:
	for i in range(SUDOKU_SIZE):
		sudoku_array.append(0)
	# 스도쿠 배열을 각각 0으로 설정. 0은 비어있는 셀
	
	for i in range(SUDOKU_SIZE):
		var array = []
		record_array.append(array)
	# record_array 초기화 설정
	
	for i in range(SUDOKU_WIDTH_SIZE):
		var array = []
		for j in range(SUDOKU_WIDTH_SIZE):
			array.append(i * SUDOKU_WIDTH_SIZE + j)
		row_array.append(array)
	# row_array 초기화 설정
	# [1,2,3,4,5,6,7,8,9] ... [72,73,74,75,76,77,78,79,80]
	
	for i in range(SUDOKU_WIDTH_SIZE):
		var array = []
		for j in range(SUDOKU_WIDTH_SIZE):
			array.append(i + j * SUDOKU_WIDTH_SIZE)
		column_array.append(array)
	# row_array 초기화 설정
	# [0,9,18,27,36,45,54,63,72] ... [8,17,26,35,44,53,62,71,80]
	
	var box_sequence = 0
	for i in range(SUDOKU_WIDTH_SIZE):
		var offset = 0
		var array = []
		array.clear()
		
		for j in range(SUDOKU_WIDTH_SIZE):
			array.append(j + offset + box_sequence)
			if (j + 1) % 3 == 0:
				offset += 6
		
		if (i + 1) % 3 == 0:
			box_sequence += 21
		else:
			box_sequence += 3
		
		box_array.append(array)
	# box_array 초기화 설정
	# [0,1,2,9,10,11,18,19,20] ... [60,61,62,69,70,71,78,79,80]

##################################################
func generate_sudoku() -> void:
	if index == SUDOKU_SIZE:
		success_to_generate = true
		return
	# 스도쿠 연산에 성공 후에는 더 이상 실행되지 않고 반환
	
	var possible_numbers = get_possible_numbers(index)
	# 입력 가능한 번호 배열
	if possible_numbers.size() > 0:
	# 입력 가능한 배열에 숫자가 있으면
		possible_numbers.shuffle()
		# 순서를 섞고
		sudoku_array[index] = possible_numbers.pop_back()
		record_array[index].append(sudoku_array[index])
		# 맨 뒤 숫자를 입력
		index += 1
		# 다음 셀 연산을 위한 설정
	else:
	# 입력 가능한 배열에 숫자가 없으면
		sudoku_array[index] = 0
		# 현재 스도쿠 배열 인덱스를 0으로 초기화
		record_array[index].clear()
		# 현재 인덱스 record_array도 초기화
		index -= 1
		# 이전 셀 연산을 위한 설정
	
	generate_audio_player.play()
	# 연산 효과음 재생

##################################################
func get_possible_numbers(idx: int) -> Array:
	var possible_numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9]
	# 기본 반환 가능한 숫자는 1부터 9까지 모두 존재
	
	for row in row_array:
	# 전체 행 배열에서
		if row.has(idx):
		# 인덱스가 포함 된 행을 찾아
			for row_index in row:
				possible_numbers.erase(sudoku_array[row_index])
			# 행 유효성 검사로 불가능 숫자를 제거
	
	for column in column_array:
	# 전체 열 배열에서
		if column.has(idx):
		# 인덱스가 포함 된 열을 찾아
			for column_index in column:
				possible_numbers.erase(sudoku_array[column_index])
			# 열 유효성 검사로 불가능 숫자를 제거
	
	for box in box_array:
	# 전체 9셀 박스 배열에서
		if box.has(idx):
		# 인덱스가 포함 된 9셀 박스를 찾아
			for box_index in box:
				possible_numbers.erase(sudoku_array[box_index])
			# 9셀 박스 유효성 검사로 불가능 숫자를 제거
	
	for stack_index in record_array[idx]:
		possible_numbers.erase(stack_index)
	# record_array 유효성 검사로 불가능 숫자를 제거
	
	return possible_numbers
	# 남은 배열 반환

##################################################
func draw_sudoku() -> void:	
	for i in range(SUDOKU_SIZE):
		var row = i / SUDOKU_WIDTH_SIZE
		var column = i % SUDOKU_WIDTH_SIZE
		# 순회 중인 i의 행과 열을 계산
		
		var x = column * CELL_SIZE + OFFSET + (column / 3) * OFFSET
		var y = row * CELL_SIZE + OFFSET + (row / 3) * OFFSET
		var value = sudoku_array[i]
		# 순회 중인 i의 좌표 계산
		
		var texture: Texture
		match value:
			0: texture = num_0
			1: texture = num_1
			2: texture = num_2
			3: texture = num_3
			4: texture = num_4
			5: texture = num_5
			6: texture = num_6
			7: texture = num_7
			8: texture = num_8
			9: texture = num_9
		# value에 따른 텍스처 설정
		
		var sprite = Sprite2D.new()
		sprite.texture = texture
		sprite.position = Vector2(x, y)
		sprite.centered = false
		add_child(sprite)
		# 스프라이트 생성 및 설정 후 자식 노드로 추가

##################################################
func _on_draw_timer_timeout() -> void:
	generate_sudoku()
	draw_sudoku()
	# 타이머가 만료될 때마다 스도쿠 연산 및 그리기
	
	if not success_to_generate:
		draw_timer.start()
	# 연산 완료 전까지만 타이머를 재가동

##################################################
func erase_random_numbers()-> void:
	var array = []
	
	while array.size() < 10:
		var random_number = randi_range(0, SUDOKU_SIZE - 1)
		if not array.has(random_number) and not sudoku_array[random_number] == 0:
			array.append(random_number)
	# 비어있지(0) 않고 겹치지 않는 인덱스 10개를 고름
	
	for idx in array:
		sudoku_array[idx] = 0
	# 비어있도록(0) 설정
	
	draw_sudoku()
	# 스도쿠를 그림
