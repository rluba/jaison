is_utf_cont :: inline (b: u8) -> bool {
	return (b & 0xc0) == 0x80;
}

parse_unicode :: (str: string) -> result: u16, success: bool {
	val, success, remainder := string_to_int(str, base = 16);
	if !success || val > 0xFFFF || remainder.count		return 0, false;
	return xx val, true;
}

encode_utf8 :: (val: u16, result: *u8) -> len: u8 {
	if val & 0xF800 {
		result[0] = xx (0xE0 | ((val & 0xF000) >> 12));
		result[1] = xx (0x80 | ((val & 0x0FC0) >> 6));
		result[2] = xx (0x80 | (val & 0x003F));
		return 3;
	} else if val & 0x0F80 {
		result[0] = xx (0xC0 | ((val & 0x0FC0) >> 6));
		result[1] = xx (0x80 | (val & 0x003F));
		return 2;
	} else {
		result[0] = xx (val & 0x7F);
		return 1;
	}
}

is_valid_utf8 :: (str: string) -> valid:bool {
	for i: 0..str.count-1 {
		cur := str[i];
		if cur >= 0x80 {
			// Must be between 0xc2 and 0xf4 inclusive to be valid
			if (cur - 0xc2) > (0xf4 - 0xc2) return false;

			if cur < 0xe0 {     // 2-byte sequence
				if i + 1 >= str.count || !is_utf_cont(str[i+1]) return false;
				i += 1;
			} else if cur < 0xf0 { // 3-byte sequence
				if i + 2 >= str.count || !is_utf_cont(str[i+1]) || !is_utf_cont(str[i+2]) return false;

				// Check for surrogate chars
				if cur == 0xed && str[i+1] > 0x9f return false;
				// ToDo: Check if total >= 0x800
				// uc = ((uc & 0xf)<<12) | ((*str & 0x3f)<<6) | (str[1] & 0x3f);
				i += 2;
			} else {	// 4-byte sequence
				if i + 3 >= str.count || !is_utf_cont(str[i+1]) || !is_utf_cont(str[i+2]) || !is_utf_cont(str[i+3]) return false;
				// Make sure its in valid range (0x10000 - 0x10ffff)
				if cur == 0xf0 && str[i + 1] < 0x90 return false;
				if cur == 0xf4 && str[i + 1] > 0x8f return false;
				i += 3;
			}
		}
	}
	return true;
}

#scope_file

#import "Basic";
