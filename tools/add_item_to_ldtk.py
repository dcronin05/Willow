import json

def add_item_entity():
    file_path = "source/levels/world.ldtk"
    
    with open(file_path, "r") as f:
        data = json.load(f)

    # Check if Item already exists
    entities = data["defs"]["entities"]
    if any(e["identifier"] == "Item" for e in entities):
        print("Item entity already exists in world.ldtk.")
        return

    print("Adding Item entity definition to LDtk schema...")
    
    # Add Item
    item_entity = {
        "identifier": "Item",
        "uid": data["nextUid"],
        "tags": [],
        "exportToToc": False,
        "allowOutOfBounds": False,
        "doc": None,
        "width": 16,
        "height": 16,
        "resizableX": False,
        "resizableY": False,
        "minWidth": None,
        "maxWidth": None,
        "minHeight": None,
        "maxHeight": None,
        "keepAspectRatio": False,
        "tileOpacity": 1,
        "fillOpacity": 1,
        "lineOpacity": 1,
        "hollow": False,
        "color": "#e0a322",
        "renderMode": "Rectangle",
        "showName": True,
        "tilesetId": None,
        "tileRenderMode": "FitInside",
        "tileRect": None,
        "uiTileRect": None,
        "nineSliceBorders": [],
        "maxCount": 0,
        "limitScope": "PerLevel",
        "limitBehavior": "MoveLastOne",
        "pivotX": 0,
        "pivotY": 0,
        "fieldDefs": [
            {
                "identifier": "itemId",
                "doc": None,
                "__type": "String",
                "searchable": False,
                "exportToToc": False,
                "allowOutOfLevelRef": False,
                "snappable": False,
                "type": "F_String",
                "isArray": False,
                "canBeNull": False,
                "arrayMinLength": None,
                "arrayMaxLength": None,
                "editorDisplayMode": "Hidden",
                "editorDisplayScale": 1,
                "editorDisplayPos": "Above",
                "editorLinkStyle": "StraightArrow",
                "editorDisplayColor": None,
                "editorAlwaysShow": False,
                "editorShowInWorld": True,
                "editorCutLongValues": True,
                "editorTextSuffix": None,
                "editorTextPrefix": None,
                "useForSmartColor": False,
                "min": None,
                "max": None,
                "regex": None,
                "acceptFileTypes": None,
                "defaultOverride": {
                    "id": "V_String",
                    "params": ["potion"]
                },
                "textLanguageMode": None,
                "symmetricalRef": False,
                "autoChainRef": False,
                "allowActionBtn": False,
                "color": None,
                "choices": None,
                "uid": data["nextUid"] + 1
            }
        ]
    }
    
    # Increment nextUid to avoid collisions
    data["nextUid"] += 2
    entities.append(item_entity)

    with open(file_path, "w") as f:
        json.dump(data, f, indent=4)
        
    print("Successfully injected Item entity into world.ldtk!")

if __name__ == "__main__":
    add_item_entity()
