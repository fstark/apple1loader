import sys
import json
import struct

def load_json_file(filename):
    try:
        with open(filename, 'r') as file:
            data = json.load(file)
        return data
    except FileNotFoundError:
        print(f"Error: File '{filename}' not found.")
    except json.JSONDecodeError:
        print(f"Error: '{filename}' is not a valid JSON file.")

def parse_hex_string(hex_string):
    parsed_values = []
    
    for char in hex_string:
        try:
            # Attempt to convert the hexadecimal character to its decimal value
            decimal_value = int(char, 16)
            parsed_values.append(decimal_value)
        except ValueError:
            # Handle non-hexadecimal characters
            print(f"Error: '{char}' is not a valid hexadecimal character.")
    
    return parsed_values

def find_identical_modulo_eight(numbers):
    seen_modulo = {}

    for num in numbers:
        modulo_eight = num % 8

        if modulo_eight in seen_modulo:
            return [seen_modulo[modulo_eight], num]

        seen_modulo[modulo_eight] = num

    return None

def to_hex( num ):
    return "0123456789ABCDEF"[num]

def load_binary_file(filename):
    try:
        with open(filename, 'rb') as file:
            binary_data = file.read()
        
        # Convert the binary data to an array of integers
        integer_array = [int(byte) for byte in binary_data]
        
        # Ensure that the integers are within the range [0, 255]
        # Check that all integers are within the range [0, 255]
        for value in integer_array:
            if not (0 <= value <= 255):
                raise ValueError(f"Value {value} is outside the valid range [0, 255]")

        return integer_array
    except FileNotFoundError:
        print(f"Error: File '{filename}' not found.")

def parse_hex_number(hex_string):
    if not (hex_string.startswith("0x") and len(hex_string) == 6 and all(c in "0123456789ABCDEF" for c in hex_string[2:].upper())):
        raise ValueError(f"Invalid hex string format or content: [{hex_string}]")

    try:
        hex_value = int(hex_string, 16)
        return hex_value
    except ValueError:
        raise ValueError("Invalid hex value")

menu = []

def add_menu( type, key, name, adrs, len, to ):
    menu.append( type )
    menu.append( adrs%256 )
    menu.append( int(adrs/256) )
    menu.append( len%256 )
    menu.append( int(len/256) )
    menu.append( to%256 )
    menu.append( int(to/256) )
    if key is not None:
        menu.append( ord(key) )
    else:
        menu.append( 0x00 )
    menu.extend( [ord(c) for c in name] )
    menu.append( 0x00 )

def add_menu_exec( key, name, adrs ):
    add_menu( 1, key, name, adrs, 0, 0 )

def add_menu_copy( key, name, adrs, len, to ):
    add_menu( 2, key, name, adrs, len, to )

def add_menu_basic( key, name, adrs, len, to ):
    add_menu( 3, key, name, adrs, len-0xb6, to )

def add_menu_skip():
    add_menu( 4, None, "", 0, 0, 0 )

def print_mapping(mem2rom, rom2mem):
    for i in range(0,16):
        if mem2rom[i*4096]<0:
            print( f"MEM 0x{i*4096:04X} -> NOT MAPPED" )
        else:
            print( f"MEM 0x{i*4096:04X} -> ROM 0x{mem2rom[i*4096]:04X}" )
    print()

    for i in range(0,8):
        print( f"ROM 0x{i*4096:04X} -> MEM 0x{rom2mem[i*4096]:04X}" )
    print()


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python makerom.py <json_file> <rom_file>")
        sys.exit( 1 )

    json_filename = sys.argv[1]
    rom_filename = sys.argv[2]


    loaded_data = load_json_file(json_filename)
    if loaded_data is None:
        sys.exit( 2 )

    map = sorted(parse_hex_string(loaded_data["map"]))
    if map==None:
        print( "There should be a top-level 'map' key" )
        sys.exit( 3 )

    dups = find_identical_modulo_eight(parse_hex_string(loaded_data["map"]))
    if dups is not None:
        print( f"Error duplicate banks {to_hex(dups[0])} and {to_hex(dups[1])} in map" )
        sys.exit( 4 )

    rom = [0] * 32768       # Rom data
    for i in range(32768):
        rom[i] = i%256
    usage = [-2] * 32768    # Which content went here (-2 == free, -1 == menu, 0-n == content)

    mem2rom = [-1] * 65536
    rom2mem = [-1] * 32768

    menu_adrs = -1

        # We fill to arrays to convert addresses
    for i in map:
        membase = 4096*i            # base address for that block in rom
        rombase = membase % 32768   # address in rom
        for j in range(4096):
            mem2rom[membase+j] = rombase+j
            rom2mem[rombase+j] = membase+j

    print_mapping(mem2rom, rom2mem)

        # copy to rom
    failed = False
    next_adrs = map[0]*4096 # First available address
    content_index = 0
    for content in loaded_data["content"]:
        # Case where the code is already in the rom (e.g. wozmon)
        if "path" not in content:
            data = []
        else:
            data = load_binary_file( content["path"] )
        patch = []
        if "patch" in content:
            patch = load_binary_file( content["patch"] )
        patch_len = len(patch)
        data[:0] = patch

        adrs = next_adrs    # Default
        if "adrs" in content:
            adrs = parse_hex_number( content["adrs"] )
        content["real_adrs"] = adrs
        content["real_len"] = len(data)
        type = content["type"]
        load_adrs = 0x280
        if "load" in content:
            load_adrs = parse_hex_number( content["load"] )
        load_adrs -= len(patch)
        content["load_adrs"] = load_adrs

        for i in range(len(data)):
            mem_adrs = adrs+i
            next_adrs = mem_adrs+1
            rom_adrs = mem2rom[mem_adrs]
            if rom_adrs==-1:
                print(f"\033[41m**** Memory at 0x{mem_adrs:04X} is not mapped when copying {content['path']} (fail at byte {i}/{len(data)}, missing {len(data)-i} bytes)\033[0m")
                failed = True
                break
            if usage[rom_adrs]!=-2:
                print( f"**** Memory clash at address 0x{mem_adrs:04X}" )
                print( f"   File {content['path']} clashes with file {loaded_data['content'][usage[rom_adrs]]['path']}" )
                failed = True
                break
            if rom_adrs>=0x3ff0 and rom_adrs<0x4010:
                print( f"0x{rom_adrs:04X}:{data[i]:02X} ", end="")
            if usage[rom_adrs]!=-2:
                print( f"**** Memory clash at address 0x{mem_adrs:04X}" )
                print( f"   File {content['path']} clashes with file {loaded_data['content'][usage[rom_adrs]]['path']}" )
                failed = True
                break
            rom[rom_adrs] = data[i]
            usage[rom_adrs] = content_index
        # Menu entry
        # if type=="exec":
        #     menu[content_index]
        print()

        if "loader" in content and content["loader"]:
            menu_adrs = next_adrs
            next_adrs += 500        # Should calc the menu size instead!

        content_index += 1
        if failed:
            break

    for rom_adrs in range(0x3ff0,0x4010):
        print( f"0x{rom_adrs:04X}:{rom[rom_adrs]:02X} ", end="")


    # Generate menu
    if not failed:
        for key in loaded_data["loader"]["keys"]:
            if key==" ":
                add_menu_skip()
            for content in loaded_data["content"]:
                if "key" in content and content["key"]==key:
                    if content["type"]=="exec":
                        add_menu_exec( key, content["menu"], content["real_adrs"] )
                    if content["type"]=="copy":
                        add_menu_copy( key, content["menu"], content["real_adrs"], content["real_len"], content["load_adrs"] )
                    if content["type"]=="basic":
                        add_menu_basic( key, content["menu"], content["real_adrs"], content["real_len"], content["load_adrs"] )
        menu.append( 0 )

        # if len(menu)>256:
        #     print( f"Menu too large {len(menu)} bytes. Must be <=256 ({len(menu)-256} bytes less)." )
        #     sys.exit( 4 )

        # Insert menu (code dup)
        if menu_adrs!=-1:
            for i in range(len(menu)):
                mem_adrs = menu_adrs+i
                next_adrs = mem_adrs+1
                rom_adrs = mem2rom[mem_adrs]
                if rom_adrs==-1:
                    print( f"**** Memory at 0x{mem_adrs:04X} is not mapped when copying menu (offset {i}/{len(data)})")
                    failed = True
                    break
                if usage[rom_adrs]!=-2:
                    print( f"**** Memory clash at address 0x{mem_adrs:04X}" )
                    print( f"   Menu clashes with file {loaded_data['content'][usage[rom_adrs]]['path']}" )
                    failed = True
                    break
                rom[rom_adrs] = menu[i]
                usage[rom_adrs] = -1

        # Print stats
    print( "Software map:" )
    content_index = 0
    total_size = 0
    for content in loaded_data["content"]:
        size = 0
        print( f"{content['path']} :\n", end="" )
        found = False
        for i in range(32768):
            if usage[i] == content_index:
                size += 1
            if not found and usage[i]==content_index:
                print( f"        0x{i:04X}/0x{rom2mem[i]:04X}-", end="")
                found = True
            else:
                if found and usage[i]!=content_index:
                    print( f"0x{i-1:04X}/0x{rom2mem[i-1]:04X} ", end="")
                    found = False
        if found:
            print( f"0x{32767:04X}/0x{rom2mem[32767]:04X} ", end="")
        print( f" ({size} bytes)" )
        total_size += size
        content_index += 1
    print( f"Total software size {total_size} bytes, menu size {len(menu)}, free {usage.count(-2)}" )

    print( "\n\nROM map:" )
    current_content = -1 # Free
    for i  in range(32768):
        new_content = usage[i]
        if new_content!=current_content:
            print( f"0x{i:04X} : ", end="" )
            if new_content>=0:
                print( f"{loaded_data['content'][new_content]['path']} (", end="" )
                for j in range(i,32768):
                    if usage[j]!=new_content:
                        break
                print( f"{j-i} bytes)" )
            else:
                if new_content==-1:
                    print( "MENU")
                if new_content==-2:
                    print( "FREE (", end="")
                    for j in range(i,32768):
                        if usage[j]!=new_content:
                            break
                    print( f"{j-i} bytes)" )
            current_content = new_content

    print( "\n\nMEM map:" )
    current_content = -1 # Free
    for i  in range(65536):
        if mem2rom[i]==-1:
            new_content = -3
        else:
            new_content = usage[mem2rom[i]]
        if new_content!=current_content:
            print( f"0x{i:04x}-0x{i+loaded_data['content'][new_content]['real_len']-1:04x} (0x{loaded_data['content'][new_content]['real_len']:04x}): ", end="" )
            if new_content>=0:
                print( f"{loaded_data['content'][new_content]['path']}", end="")
                if "load_adrs" in loaded_data['content'][new_content]:
                    print( f" (load 0x{loaded_data['content'][new_content]['load_adrs']:04X})", end="")
                print()
            else:
                if new_content==-1:
                    print( "MENU")
                if new_content==-2:
                    print( "FREE (", end="")
                    for j in range(i,65536):
                        if mem2rom[j]==-1 or usage[mem2rom[j]]!=-2:
                            break
                    print( f"{j-i} bytes)" )
                if new_content==-3:
                    print( "NOT MAPPED")
            current_content = new_content

    if failed:
        sys.exit( -4 )

    for rom_adrs in range(0x3ff0,0x4010):
        print( f"0x{rom_adrs:04X}:{rom[rom_adrs]:02X} ", end="")

    try:
        # Open the binary file for writing in binary mode
        with open( rom_filename, 'wb') as file:
            # Write each integer as a single byte
            for num in rom:
                # file.write(num.to_bytes(1, byteorder='big'))
                file.write(bytes([num]))
    except IOError:
        print(f"Error writing to '{binary_filename}'.")

    adrs = 0x0000
    end = 0xC000
    len = end-adrs

    mem = [0] * 65536
    for i in range(65536):
        mem[i] = rom[mem2rom[i]]

    # print_mapping(mem2rom, rom2mem)

    # for rom_adrs in range(0x3ff0,0x4010):
    #     print( f"ROM 0x{rom_adrs:04X} = {rom[rom_adrs]:02X}")
    # print()

    # for ram_adrs in range(0xbff0,0xc010):
    #     print( f"RAM 0x{ram_adrs:04X} = {rom[mem2rom[ram_adrs]]:02X}")
    # print()

    array = [76, 79, 65, 68, 58, int(adrs/256), adrs%256, 68, 65, 84, 65, 58]
    array.extend( mem[adrs:adrs+len] )
    print( f"Writing snapshot from 0x{adrs:04X} to 0x{adrs+len:04X}" )
    try:
        with open( "a.snp", 'wb') as file:
            for num in array:
                file.write(bytes([num]))
    except IOError:
        print(f"Error generating mame snapshot 'a.snp'.")
