# Endurance

OPFOR has been pushing BLUFOR from the area for several days, and the HQ has decided to evacuate all the remaining BLUFOR forces. 
You and several other squads were cut off during the retreat, and so must hold off the enemy until you find a way out.
This is a two-part mission, with holding off enemies in the first stage and transporting friendly squads in the second part.

# Editing mission

- To migrate this mission to another map simply create an empty scenario with the map you like, move all the sqf files into its directory and place the units controlled by players.

- To create a loadout set, which controls which vehicles and unit compositions are used, copy an existing loadout set and change the values you want with the class names of units or vehicles you want. It's important that all vehicles and units are from the appropriate side, e.g. **EnemyAAClass** should belong to OPFOR in eden editor and config files. *you can leave **EnemyPlaneWeapon** and **EnemyPlaneMode** as blank strings*.

  After that in *description.ext* in **Params.set** add your loadout set name in **texts[]** and a unique number in **values[]**.

  The last thing is to add a switch case in the beginning of *init.sqf* with the value that corresponds to the value you added in *description.ext*, and set the SetPath variable as a relative path to your loadout set file.
