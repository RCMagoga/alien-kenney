# Esse script tem como finalidade gerar a escada, para isso, deve-se posicionar o objeto
# na posição onde ficará a parte de baixo da escada e, na variavel exportada, inserir o 
# tamanho que ela deverá ter.

extends Area2D
# Usado para determinar o tamanho da escada no mapa (Objeto Ladder)
@export var ladder_height: int = 2

@onready var collision: CollisionShape2D = $CollisionShape2D
# Tamanho padrão das imagens
const tile_size: int = 64

func _ready() -> void:
	# Carrega as imagens
	var top_texture = preload("res://assets/alien - kenney assets/Sprites/Tiles/ladder_top.png")
	var middle_texture = preload("res://assets/alien - kenney assets/Sprites/Tiles/ladder_middle.png")
	var bottom_texture = preload("res://assets/alien - kenney assets/Sprites/Tiles/ladder_bottom.png")
	# Calcula a posição exata dos tiles para alinhar com o mapa
	# posição onde foi inserido o objeto no mapa
	var x = floor(position.x / tile_size) * tile_size
	var y = floor(position.y / tile_size) * tile_size
	# Coloca a escada no tile escolhido no mapa, iniciando pela parte de baixo (bottom)
	self.position = Vector2(x + (tile_size / 2.0), y + (tile_size / 2.0))
	# Percorre todo o comprimento da escada
	for i in ladder_height:
		# Textura de cada sprite
		var texture
		# Instância Sprite2D para colocar em cada tile da escada
		var sprite = Sprite2D.new()
		# Se for 0 ( primeiro andar ) será bottom
		if i == 0:
			texture = bottom_texture
		# Se for o último andar, será top
		elif i == ladder_height - 1:
			texture = top_texture
		# Os outros andaras são considerados middle
		else:
			texture = middle_texture
		# Determina cada posição de cada sprite
		sprite.position = Vector2(-tile_size / 2.0, -i * tile_size - 32)
		# Determina a textura de cada andar
		sprite.texture = texture
		# Determina a canto superior esquerdo como posição inicial
		sprite.centered = false
		# Adiciona a árvore de nó
		add_child(sprite)
	# Determina a posição que será iniciada a colisão
	collision.position = Vector2(0, -64 * (ladder_height / 2.0) +32)
	# Determina o tamanho baseado no tamanha escolhido para a escada
	collision.shape.size = Vector2(tile_size, tile_size * ladder_height)
	# Coloca a colisão para ser renderizada na frente da escada
	move_child(collision, get_children().size())
