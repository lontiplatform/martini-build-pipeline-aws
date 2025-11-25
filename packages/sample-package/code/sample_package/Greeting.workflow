{
    "inputModel": {
        "name": "input",
        "type": "model",
        "gloopProperties": [
            {
                "name": "name"
            }
        ]
    },
    "outputModel": {
        "name": "output",
        "type": "model",
        "gloopProperties": [
            {
                "name": "message"
            }
        ]
    },
    "nodes": [
        {
            "id": "867b68a4-e985-42c7-aae2-65cf7ac3d153",
            "type": "api_invocation_trigger",
            "data": {
                "name": "",
                "description": ""
            },
            "position": {
                "x": 100,
                "y": 100
            },
            "positionAbsolute": {
                "x": 100,
                "y": 100
            },
            "width": 372,
            "height": 86
        },
        {
            "id": "bf9d1e86-ecc8-49dd-b61a-3a4c2893ca7f",
            "type": "webhook",
            "position": {
                "x": 93.546875,
                "y": 289
            },
            "data": {
                "name": "For /greeting requests",
                "description": "",
                "httpMethods": [
                    "GET"
                ],
                "urlPath": "/greeting",
                "enabled": true
            },
            "width": 372,
            "height": 86,
            "positionAbsolute": {
                "x": 93.546875,
                "y": 289
            }
        },
        {
            "id": "8553562f-85cd-4468-ac28-63eed74c09ac",
            "type": "map",
            "position": {
                "x": 596.546875,
                "y": 289
            },
            "data": {
                "name": "Set the message",
                "description": "",
                "step": {
                    "lines": [
                        {
                            "type": "set",
                            "expression": "\"Hello, $name\"",
                            "evaluate": true,
                            "to": [
                                "message"
                            ]
                        }
                    ]
                }
            },
            "width": 372,
            "height": 86,
            "positionAbsolute": {
                "x": 596.546875,
                "y": 289
            }
        }
    ],
    "edges": [
        {
            "id": "rf__edge-bf9d1e86-ecc8-49dd-b61a-3a4c2893ca7f-8553562f-85cd-4468-ac28-63eed74c09ac",
            "source": "bf9d1e86-ecc8-49dd-b61a-3a4c2893ca7f",
            "sourceHandle": "out",
            "target": "8553562f-85cd-4468-ac28-63eed74c09ac"
        }
    ]
}
