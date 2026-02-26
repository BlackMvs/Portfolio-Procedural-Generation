# Procedural Generation System 

> **A procedural voxel world generation tool for Godot 4.6**  
> **Project is still in development. There will be incomplete systems or bugs.**

This project solves the time-consuming nature of level design by providing a visual, drag-and-drop toolkit that generates fully playable worlds in seconds. It ships with working defaults out of the box: terrain, enemies, structures, while keeping deep customisation options available for those who want them.

<img width="1919" height="1079" alt="Screenshot 2026-02-23 231045" src="https://github.com/user-attachments/assets/dd8892eb-2831-4fc9-a7e9-da6a100cd59d" />

---

## Overview

This is an open-source Godot "tool" designed to remove the friction of early-stage level design. Drop the tool folder into your project, drag the script onto the Node that you want to generate, and hit Play. You'll have a generated world with terrain, navigable enemies, and spawned entities ready to explore. Or you can change the assets and make anything you want. 

Because it is built as a **foundation rather than a black box**, every system is designed to be subclassed, swapped, or stripped out. The tool becomes part of your project and grows with it. This won't be just another tool sitting on top of your project.

---

## Requirements

| Requirement | Version |
|---|---|
| Godot | **4.6** |
| Platform | Windows / macOS / Linux |

No additional dependencies or addons are required.  
This tool was designed using the version specified. Higher versions may be used, but depending on the changes that were made, the tool might not work appropriately. 

---

## Installation

1. Download or clone this repository.
2. Copy the `tool/` folder into your project's preferred directory.

## Quick Usage 
1. Add any Node3D to your scene tree.
2. Drag and drop the script `!WorldGenerator` (found in the `tool/` directory) onto the node. 
3. Press **Run Project** / **Run Current Scene**. A world will generate using the default presets. (Make sure you have a camera or light to be able to see the world.)

---

## Usage / Demo 

The ultimate goal of this project is to be able to generate anything that you want, however you want it, with the only limitation being that generated assets will be cubes or rectangles and without having to learn a complex system where you have no control over it. 

### Generate World for Testing 

There are defaults added and created for the world. The initial and original version of this tool is for generating a world that you want. So, as a default, the moment you drag it into the scene and press play, it will generate a voxel world. If you just want a quick world where you can test your game or have a map to run around in, this easy drag-and-drop approach will sort it for you. 

<img width="1919" height="1079" alt="Screenshot 2026-02-23 231026" src="https://github.com/user-attachments/assets/4a84629d-6bab-43bb-9107-31a1cb438285" />


### Flat World 
You can also generate a flat world by simply changing the `amplitude` to `0`.  
You can change the voxels to modular dungeon parts and the flat world will generate dungeon floors for you.

<img width="1919" height="1079" alt="image" src="https://github.com/user-attachments/assets/e22f73ac-4cfa-4d63-93ee-211f7ebe2978" />


### Add youw own voxels  
You can add your own voxels to the generation by simply making your own voxel scene.  

Create your scene by extending from the `Template Voxel` (You can create your own as well, this is only used for simplicity):  
The template only has this simple nodes, set at the default voxel size for the generation of 1m.  
<img width="266" height="99" alt="image" src="https://github.com/user-attachments/assets/21ea66e1-68b4-4ca5-afa1-cb7e2038b8cc" />  

Now simply add your mesh to it. You can also add a script, or any other nodes. Make it do what you want it to do. For example, a simple gold voxel that will print a message if we step on it:  
<img width="707" height="353" alt="image" src="https://github.com/user-attachments/assets/5fcc9586-d746-4fba-bb9a-9bd3804f6eaa" />
<img width="439" height="210" alt="image" src="https://github.com/user-attachments/assets/5973bf19-38e2-4644-91bf-551c6194541f" />

You just made a new voxel, congrats! Now make a new VoxelConfiguration in your generator and drag-and-drop your scene into the `Voxel Scene`:  
<img width="412" height="658" alt="image" src="https://github.com/user-attachments/assets/ffb3214b-b3e5-46b5-874c-1cfd25504406" />  

Press `Run` and enjoy your bigger and customisable world!! 
<img width="1919" height="1079" alt="image" src="https://github.com/user-attachments/assets/6d4b48fa-b9f7-41d8-8183-3215a67539b1" />


### Non-World Generation - Item Generation 

You can use the generator to make other items too. 

In this example, we created 9 total parts for a modular sword (all fitting a cube, meaning they are the same length). We set the generator to use 3 layers: handle, middle blade, and top blade. We then added the voxels for each and assigned them to their respective layers. Now, when using the script, we can generate any sword we want using those combinations.  

With a 3×3×3 modular combination, if you were to save all different sword combinations you would have 27 different assets, each taking up memory space. But with this approach, you only have 9 parts (each less than a full model since it's 1/3 of one) and you just need to save the seed of the generation. Now you can recreate that same sword by storing a single int instead of many scenes. This doesn't seem very impactful with these numbers, but if I had 10 handles, 10 middle blades, and 10 tips, that would be 1,000 different sword combinations, 1,000 different assets taking up a lot of space, versus 30 total parts plus 1 int for each combination. 

(The 3rd layer was messed up on purpose so you can see the modular parts used to make the swords)
<img width="1919" height="1079" alt="Screenshot 2026-02-23 230727" src="https://github.com/user-attachments/assets/385d00a6-3746-4b20-b4e8-77d91e191623" />

(Inspector settings)  
<img width="404" height="1707" alt="image" src="https://github.com/user-attachments/assets/d4577ec7-86fd-4f20-b897-6799f8132dc1" />
<img width="398" height="825" alt="image" src="https://github.com/user-attachments/assets/8294d0ce-ffa1-4d7d-80f0-4f7f850e0e06" />


### Entity Spawn
You can also generate entities in the world. They work as a group for the settings. For example, if you add a sheep, you can set how many chunks apart each group spawns and how many spawn per group (e.g. every 10 chunks will spawn a group of 50 sheep). 

For the enemies, there are 3 states. First is idle, if you have not selected any `behaviour` settings, their main state will be idle. Then you have 2 behaviours. The first is patrolling: the entity picks a random nearby location and moves toward it. The second is chase: you will need to add a target that they will chase. 

Behaviour combinations:
- `can_patrol=false`, `can_chase=false` → Idle (stands still forever)
- `can_patrol=true`,  `can_chase=false` → Patrol only (ignores player)
- `can_patrol=false`, `can_chase=true` → Chase only (never patrols, immediately chases if in range)
- `can_patrol=true`,  `can_chase=true` → Patrol until player detected, then chase; return on abandon

The default enemies use a default controller. If you want extra functionality, you can either modify the controller yourself and add more logic to it, or build your own. If you do want different states, make sure you add them to the `!WorldGenerator` so that you can set them up when you want to generate. (If unsure, you can follow the same logic that is there now.) 

(Inspector view)  
<img width="403" height="857" alt="image" src="https://github.com/user-attachments/assets/9fb958dd-341c-4c6b-b935-00beb52f1e0c" />


### Chunk Rendering and World Size 

There are a couple of options for chunk rendering:  
1. Generate a fixed world.
2. Generate an endless world.
3. Generate a fixed world that follows the player.
4. Generate an endless world that follows the player.


### Manual Editing 
> **This will only work with a limited-size world that has no chunk rendering enabled.**

> **Buttons not fully implemented yet**

If you want a generated world but also want to place your own objects in it, you have a couple of options. In the `editor` sub-category, there are 2 buttons: one to generate the world inside the editor and one to clear the world. The generate world button does the same thing as pressing play, but in this case it adds the generated content to your scene as new objects. From here you have 2 options:

1. Keep it as it is and add your own objects. Congratulations, you have a fully playable scene!
2. If you want to save storage, generate the world using the button, but use a set seed (do not use a randomly generated one) and set it in the inspector to always use that seed. Add your own objects, and when you're done, press the `Clear world` button. Despite the naming, this will only clear the generated items. Now when you play that scene, it will still generate the same world you edited, but when you save the scene, it won't have thousands (if not millions) of objects eating away at storage. 

---

## Essential Files 

This tool is made so that it can easily be added to your project and grow with it. You can edit, add, expand, and do whatever you want to it. But with that said, there are some limitations, mainly the files that are required for the tool to function. These define the core interfaces that the generator depends on:

`tool/EnemyDefaults/!EnemyConfiguration.gd`  
`tool/EnemyDefaults/!EnemySpawner.gd`  
`tool/EnemyDefaults/!EntityBase.gd`  
`tool/TerrainDefaults/!TerrainLayer.gd`  
`tool/VoxelDefaults/!VoxelConfiguration.gd`  
`tool/!WorldGenerator`  

Everything else outside of those scripts can be removed. However, keep in mind that if you remove the defaults, the generator will not be able to generate the default cubes and default enemies. This means every time you use it, you will need to add your own assets and remove the defaults (or remove the defaults from the code and add your own).
