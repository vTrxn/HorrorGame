import json
import struct

with open("Map.glb", "rb") as f:
    magic = f.read(4)
    version = struct.unpack("<I", f.read(4))[0]
    length = struct.unpack("<I", f.read(4))[0]
    
    chunk_len = struct.unpack("<I", f.read(4))[0]
    chunk_type = f.read(4)
    if chunk_type == b'JSON':
        json_data = f.read(chunk_len).decode('utf-8')
        gltf = json.loads(json_data)
        
        min_vals = [float('inf'), float('inf'), float('inf')]
        max_vals = [float('-inf'), float('-inf'), float('-inf')]
        
        for accessor in gltf.get('accessors', []):
            if 'min' in accessor and 'max' in accessor and len(accessor['min']) == 3:
                for i in range(3):
                    if accessor['min'][i] < min_vals[i]: min_vals[i] = accessor['min'][i]
                    if accessor['max'][i] > max_vals[i]: max_vals[i] = accessor['max'][i]
        
        print("MIN:", min_vals)
        print("MAX:", max_vals)
        center = [
            (min_vals[0] + max_vals[0]) / 2,
            (min_vals[1] + max_vals[1]) / 2,
            (min_vals[2] + max_vals[2]) / 2
        ]
        print("CENTER:", center)
