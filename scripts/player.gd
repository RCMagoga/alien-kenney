extends CharacterBody2D

@onready var animation: AnimationPlayer = $AnimationPlayer				# Controla a animação
@onready var sprite: Sprite2D = $Sprite2D								# Renderiza a imagem
@onready var collisor: CollisionShape2D = $Collision					# Colissor para contato físico
@onready var sound: AudioStreamPlayer2D = $AudioStreamPlayer2D			# Controla audio
@onready var can_stand_up_area: Area2D = $CanStandUpArea				# Verifica se o player pode levantar após o crouch

const gravity: int = 1000
const speed: int = 400

var life: int = 100
var dir: float = 0						# armazena a direção atual para atualizar posição
var current_dir: int = 0				# armazena a última direção para manter o flip_h da imagem
var current_animation: String = "idle"	# armazena o estado atual para atualizar a animação
var crouch_speed: int = 200				# controla o estado de crouch e é usado como valor somado a velocidade no estado de crouch
var can_climb: bool = false				# quando em contato com a escada, autoriza o player a subir a escada
var is_climbing: bool = false			# controla se o player está ou não usando a escada
var is_crouching: bool = false			# controla se o player está ou não se arrastando
var can_stand_up: bool = true			# Controla se, após o crouch, o player pode levantar, ou seja, não tem blocos acima dele
var took_damage: bool = false			# ativa quando o player tomar dano
var damage_boost: Vector2 = Vector2(0,0)# Responsável por dar o impulso após o dano na direção contrária do contato
var enimie_collisor: CollisionShape2D	# Armazena o tamanho do último ínimigo que colidiu com o player

# Sons usados no player
var jump_sound
var hurt_sound
var crouch_sound

func _ready() -> void:
	# Carrega os sons na memória
	jump_sound = preload("res://assets/alien - kenney assets/Sounds/sfx_jump.ogg")
	hurt_sound = preload("res://assets/alien - kenney assets/Sounds/sfx_hurt.ogg")
	crouch_sound = preload("res://assets/alien - kenney assets/Sounds/sfx_bump.ogg")

func _physics_process(delta: float) -> void:
	# Se não estiver no chão, a força da gravidade puxa para baixo
	# Se estiver subindo a escada, a força da gravidade não funciona
	if (not is_on_floor() and not is_climbing) or damage_boost != Vector2.ZERO:
		velocity.y += gravity * delta
	# Se o player não tiver sofrido dano, segue normal
	if not took_damage:
		move_player()
		crouch_player()
		jump_player()
		climb_player()
	# Se sofrer dano, pula tudo acima e executa o método abaixo
	# Estado de sofrer dano tem prioridade sobre todos os outros
	else:
		get_hit()
	
	change_animation()
	# método do CharacterBody2D, atualiza a posição com relação a velocidade
	move_and_slide()

func move_player() -> void:
	# Se o player estiver se arrastando ou tiver sido atingido, sai do método direto
	if is_crouching: return
	dir = Input.get_action_strength("walk_right") - Input.get_action_strength("walk_left")
	velocity.x = speed * dir
	# atualiza a última posição sem considerar o zero gerado pelos inputs do dir
	if dir == 1: current_dir = 1
	elif dir == -1: current_dir = -1

func crouch_player() -> void:
	# Não funciona se estiver usando a escada ou ja estiver se arrastando
	if Input.is_action_just_pressed("crouch") and dir != 0 and not is_climbing and not is_crouching:
		# Habilita a área para detectar a colisão antes de levantar
		can_stand_up_area.set_monitoring(true)
		is_crouching = true
		velocity.x = (crouch_speed + speed) * current_dir
		# Ativa o som quando arrastando, se o som não estiver sendo usado
		if not sound.playing:
			sound.stream = crouch_sound
			sound.play()
		# Versão criada no Godot 4 como alternativa para o Timer
		# nesse caso, espera 1s para resetar a crouch_speed
		await get_tree().create_timer(0.7).timeout
		is_crouching = false
		# Desabilita a área superior caso o player possa levantar após o crouch
		if can_stand_up:
			can_stand_up_area.set_monitoring(false)

func jump_player() -> void:
	# Permite o pulo apenas se estiver no chão e o espaço for pressionado
	# ou
	# Permite o pulo se não estiver no chão mas estiver usando a escada
	if ( is_on_floor() or is_climbing ) and Input.is_action_just_pressed("jump"):
		velocity.y -= speed
		is_climbing = false
		# Ativa o som de pulo se o som não estiver sendo usado
		if not sound.playing:
			sound.stream = jump_sound
			sound.play()

func climb_player() -> void:
	# Armazena se está ou não usando a escada
	# Para subir
	var go_up = Input.is_action_pressed("climb")
	# Para descer
	var go_down = Input.is_action_pressed("down")
	# Se estiver na área da escada e estiver usando para subir ou descer permite o uso da escada
	if can_climb and (go_up or go_down):
		is_climbing = true
		# Subtrai posição para subir
		if go_up: velocity.y = - 200
		# Soma posição para descer
		elif go_down: velocity.y = 200
	# Usado para zerar a velocidade nos casos:
	# se o player estiver em queda, entrar em contato com a escada e começar a usar a escada
	# se o player estiver usando a escada e parar
	elif is_climbing and (not go_up and not go_down): velocity.y = 0

func get_hit() -> void:
	# Armazena a diferença das posições globais do objeto collisor e do player
	var delta_y = (collisor.global_position.y - (collisor.shape.size.y / 2)) - (enimie_collisor.global_position.y - (enimie_collisor.shape.size.y / 2))
	var delta_x = (collisor.global_position.x - (collisor.shape.size.x / 2)) - (enimie_collisor.global_position.x - (enimie_collisor.shape.size.x / 2))
	# Se o boost for zero, o objeto não tomou dano
	if damage_boost == Vector2.ZERO:
		# Executa o som se tiver tomado dano
		if not sound.playing:
			sound.stream = hurt_sound
			sound.play()
		# Contato por cima
		if abs(roundi(delta_y)) >= collisor.shape.size.y - 3 and abs(roundi(delta_y)) <= collisor.shape.size.y + 3:
			damage_boost = Vector2(250 * current_dir, -250)
		# Contato por baixo
		elif abs(roundi(delta_y)) >= enimie_collisor.shape.size.y - 3 and abs(roundi(delta_y)) <= enimie_collisor.shape.size.y + 3:
			damage_boost = Vector2(250 * current_dir, -250)
		# Contato pela esquerda
		elif abs(roundi(delta_x)) >= collisor.shape.size.x - 3 and abs(roundi(delta_x)) <= collisor.shape.size.x + 3:
			damage_boost = Vector2(250 * -current_dir, velocity.y)
		# Contato pela direita
		elif abs(roundi(delta_x)) >= enimie_collisor.shape.size.x - 3 and abs(roundi(delta_x)) <= enimie_collisor.shape.size.x + 3:
			damage_boost = Vector2(250 * -current_dir, velocity.y)
		velocity = damage_boost

func change_animation() -> void:
	if took_damage:
		current_animation = "hit"
	elif is_climbing:
		current_animation = "climb"
	# Permanece na estado de crouch se:
	# O temporizador do crouch não terminar e
	# Tiver algum bloco acima dele após o crouch
	elif is_crouching or not can_stand_up:
		current_animation = "crouch"
	elif not is_on_floor():
		current_animation = "jump"
	elif  dir != 0:
		current_animation = "walk"
	else:
		current_animation = "idle"
	# ativa a animação atual
	animation.play(current_animation)
	# Pausa a animação caso esteja usando a escada e ficou parado
	if velocity.y == 0 and is_climbing:
		animation.pause()
	# muda a direção da imagem
	sprite.flip_h = true if current_dir == -1 else false
# Retorna contato com area (nó que não são CharacterBody2D)
func _on_contact_area_area_entered(area: Area2D) -> void:
	# Autoriza a interação com a escada
	if area.is_in_group("ladder"):
		can_climb = true

func _on_contact_area_area_exited(area: Area2D) -> void:
	# Reseta configuração da escada ao perder o contato com a escada
	if area.is_in_group("ladder"):
		can_climb = false
		is_climbing = false
# Retorna contato com body (nó que são CharacterBody2D)
func _on_contact_area_body_entered(body: Node2D) -> void:
	# Verifica se o corpo de colisão está no grupo de inimigos
	if body.is_in_group("enemies"):
		# Variavel que bloqueia qualquer outra lógica quando o player estiver tomando dano
		took_damage = true
		# armazena o collisor do inimigo
		enimie_collisor = body.get_node("CollisionShape2D")
		# Aguarda o fim da animação
		await get_tree().create_timer(0.6).timeout
		took_damage = false
		damage_boost = Vector2.ZERO
# Retorna contato com a área na parte superior
func _on_can_crouch_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("solid_map") and is_crouching:
		can_stand_up = false

func _on_can_stand_up_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("solid_map"):
		can_stand_up = true
		# Usada para adiar a parada o monitoramento, onde será executada no próximo frame
		# evitando erro de desativar um método que está em execução
		can_stand_up_area.set_deferred("monitoring", false)
