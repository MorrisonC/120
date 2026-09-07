import os
import struct
import hashlib

def patch_pck(orig_pck_path, game_dir, output_pck_path):
    if not os.path.exists(orig_pck_path):
        print(f"Error: {orig_pck_path} does not exist.")
        return False

    with open(orig_pck_path, 'rb') as f:
        pck_bytes = bytearray(f.read())

    magic = pck_bytes[0:4]
    if magic != b'GDPC':
        print(f"Error: Invalid PCK magic {magic}")
        return False

    file_base = struct.unpack('<Q', pck_bytes[24:32])[0]
    print(f"File base offset in PCK header: {file_base}")

    file_count = struct.unpack('<I', pck_bytes[96:100])[0]
    pos = 100
    entries = []

    for _ in range(file_count):
        p_len = struct.unpack('<I', pck_bytes[pos:pos+4])[0]
        p_start = pos + 4
        path_str = pck_bytes[p_start:p_start+p_len].decode('utf-8', errors='ignore').rstrip('\x00')
        off_pos = p_start + p_len
        offset, size = struct.unpack('<QQ', pck_bytes[off_pos:off_pos+16])
        md5 = pck_bytes[off_pos+16:off_pos+32]
        flags = struct.unpack('<I', pck_bytes[off_pos+32:off_pos+36])[0]

        entries.append({
            'path_start': p_start,
            'path_len': p_len,
            'path': path_str,
            'off_pos': off_pos,
            'offset': offset,
            'size': size,
            'md5_pos': off_pos + 16,
            'flags': flags
        })
        pos = off_pos + 36

    # 1. Neutralize ONLY .gd.remap index entries (do NOT touch .tscn.remap or other scene remaps)
    remap_renamed = 0
    for e in entries:
        path = e['path']
        p_start = e['path_start']
        p_len = e['path_len']

        if path.endswith('.gd.remap'):
            new_path = path[:-6] + '.rema_'
            new_path_bytes = new_path.encode('utf-8')
            new_path_padded = new_path_bytes + b'\x00' * (p_len - len(new_path_bytes))
            pck_bytes[p_start:p_start+p_len] = new_path_padded
            remap_renamed += 1

    # 2. Update .gdc entries to .gd and append .gd text content
    append_offset_abs = len(pck_bytes)
    appended_bytes = bytearray()

    gd_patched = 0
    for e in entries:
        path = e['path']
        p_start = e['path_start']
        p_len = e['path_len']
        off_pos = e['off_pos']
        md5_pos = e['md5_pos']

        if path.endswith('.gdc'):
            gd_path = path[:-1]  # .gd
            rel_path = gd_path.replace('res://', '')
            local_path = os.path.join(game_dir, rel_path)

            if os.path.exists(local_path):
                with open(local_path, 'rb') as f_script:
                    gd_content = f_script.read()

                # Update path in index
                new_path_bytes = gd_path.encode('utf-8')
                new_path_padded = new_path_bytes + b'\x00' * (p_len - len(new_path_bytes))
                pck_bytes[p_start:p_start+p_len] = new_path_padded

                # Actual position in file where gd_content will live
                actual_file_pos = append_offset_abs + len(appended_bytes)
                # Stored offset in index MUST be relative to file_base!
                new_stored_offset = actual_file_pos - file_base
                new_size = len(gd_content)
                new_md5 = hashlib.md5(gd_content).digest()

                struct.pack_into('<QQ', pck_bytes, off_pos, new_stored_offset, new_size)
                pck_bytes[md5_pos:md5_pos+16] = new_md5

                appended_bytes += gd_content
                pad = (16 - (new_size % 16)) % 16
                appended_bytes += b'\x00' * pad

                gd_patched += 1

    pck_bytes += appended_bytes
    with open(output_pck_path, 'wb') as f_out:
        f_out.write(pck_bytes)

    print(f"Patched {remap_renamed} .gd.remap entries and {gd_patched} .gdc scripts in {output_pck_path}")
    return True

if __name__ == '__main__':
    orig_bak = 'web_build/index.pck.bak'
    if not os.path.exists(orig_bak) and os.path.exists('web_build/index.pck'):
        import shutil
        shutil.copyfile('web_build/index.pck', orig_bak)

    patch_pck(orig_bak, 'game', 'web_build/index.pck')
