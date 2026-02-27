extends Node

#----------------------------INSTANCE FIELDS------------------------------------
#===SEEDS ===
var hardCodedSeed : bool = true
var fastNoiseLiteGenerator : FastNoiseLite
var currentSeed : int = 742174621

var defaultSeeds : Array[int] = [742174621, 685026824, 344285, 564641, 990427]

#===WORLD SIZE ===
var worldSize : Vector3

#...............................................................................


#---------------------CONTRUCTOR AND PROCESSES----------------------------------
func _ready() -> void:
	fastNoiseLiteGenerator = FastNoiseLite.new()
	if hardCodedSeed:
		fastNoiseLiteGenerator.set_seed(currentSeed)
	else:
		currentSeed = randi()
		fastNoiseLiteGenerator.set_seed(currentSeed)

##Reset the seed to the default value 
func resetSeedToDefault() -> void:
	currentSeed = defaultSeeds.get(0)
#...............................................................................
