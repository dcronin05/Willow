import json
import os

# Create 25x15 grid of 0s (empty)
grid = [0] * (25 * 15)

# Add floor at row 13 (index 12, so elements 300 to 324)
for i in range(300, 325):
    grid[i] = 1

ldtk_data = {
    "__header__": {
        "fileType": "LDtk Project JSON",
        "app": "LDtk",
        "appVersion": "1.5.3"
    },
    "jsonVersion": "1.5.3",
    "worldLayout": "Free",
    "worldGridWidth": 400,
    "worldGridHeight": 240,
    "defaultLevelWidth": 400,
    "defaultLevelHeight": 240,
    "defaultGridSize": 16,
    "bgColor": "#ffffff",
    "defs": {
        "layers": [
            {
                "__type": "Entities",
                "identifier": "Entities",
                "type": "Entities",
                "uid": 3,
                "gridSize": 16,
                "displayOpacity": 1,
                "pxOffsetX": 0,
                "pxOffsetY": 0,
                "intGridValues": []
            },
            {
                "__type": "IntGrid",
                "identifier": "Collisions",
                "type": "IntGrid",
                "uid": 1,
                "gridSize": 16,
                "displayOpacity": 1,
                "pxOffsetX": 0,
                "pxOffsetY": 0,
                "intGridValues": [
                    { "value": 1, "identifier": "Wall", "color": "#000000" }
                ],
                "tilesetDefUid": 2
            }
        ],
        "entities": [
            {
                "identifier": "Player",
                "uid": 4,
                "width": 16,
                "height": 32,
                "color": "#ff0000",
                "fieldDefs": []
            },
            {
                "identifier": "Sign",
                "uid": 5,
                "width": 16,
                "height": 16,
                "color": "#0000ff",
                "fieldDefs": [
                    {
                        "identifier": "text",
                        "__type": "String",
                        "uid": 6,
                        "type": "F_String",
                        "isArray": False,
                        "canBeNull": False
                    }
                ]
            }
        ],
        "tilesets": [
            {
                "identifier": "Tileset",
                "uid": 2,
                "relPath": "../images/tileset.png",
                "pxWid": 32,
                "pxHei": 16,
                "tileGridSize": 16,
                "__cWid": 2,
                "__cHei": 1,
                "spacing": 0,
                "padding": 0,
                "tags": [],
                "enumTags": []
            }
        ],
        "enums": [],
        "externalEnums": [],
        "levelFields": []
    },
    "levels": [
        {
            "identifier": "Room_1",
            "iid": "room-1-iid",
            "uid": 7,
            "pxWid": 400,
            "pxHei": 240,
            "worldX": 0,
            "worldY": 0,
            "bgColor": "#ffffff",
            "__neighbours": [],
            "fieldInstances": [],
            "layerInstances": [
                {
                    "__identifier": "Entities",
                    "__type": "Entities",
                    "__cWid": 25,
                    "__cHei": 15,
                    "__gridSize": 16,
                    "__opacity": 1,
                    "__pxTotalOffsetX": 0,
                    "__pxTotalOffsetY": 0,
                    "layerDefUid": 3,
                    "levelId": 7,
                    "entityInstances": [
                        {
                            "__identifier": "Player",
                            "iid": "player-iid",
                            "__grid": [12, 6],
                            "__pivot": [0, 0],
                            "__tags": [],
                            "px": [200, 100],
                            "defUid": 4,
                            "fieldInstances": []
                        },
                        {
                            "__identifier": "Sign",
                            "iid": "sign-1-iid",
                            "__grid": [15, 11],
                            "__pivot": [0, 0],
                            "__tags": [],
                            "px": [250, 176],
                            "defUid": 5,
                            "fieldInstances": [
                                { "__identifier": "text", "__type": "String", "__value": "Sign 1: I am the left sign!", "defUid": 6 }
                            ]
                        },
                        {
                            "__identifier": "Sign",
                            "iid": "sign-2-iid",
                            "__grid": [16, 11],
                            "__pivot": [0, 0],
                            "__tags": [],
                            "px": [270, 176],
                            "defUid": 5,
                            "fieldInstances": [
                                { "__identifier": "text", "__type": "String", "__value": "Sign 2: I am the right sign!", "defUid": 6 }
                            ]
                        }
                    ],
                    "intGridCsv": [],
                    "autoLayerTiles": [],
                    "gridTiles": []
                },
                {
                    "__identifier": "Collisions",
                    "__type": "IntGrid",
                    "__cWid": 25,
                    "__cHei": 15,
                    "__gridSize": 16,
                    "__opacity": 1,
                    "__pxTotalOffsetX": 0,
                    "__pxTotalOffsetY": 0,
                    "layerDefUid": 1,
                    "levelId": 7,
                    "entityInstances": [],
                    "intGridCsv": grid,
                    "autoLayerTiles": [],
                    "gridTiles": []
                }
            ]
        }
    ]
}

import os

# Get the directory where this script is located
script_dir = os.path.dirname(os.path.abspath(__file__))
levels_dir = os.path.join(script_dir, '..', 'source', 'levels')
os.makedirs(levels_dir, exist_ok=True)

output_file = os.path.join(levels_dir, 'world.ldtk')
with open(output_file, 'w') as f:
    json.dump(ldtk_data, f, indent=2)

print(f"✅ Generated {output_file}")
