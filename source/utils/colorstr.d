/++
Functions and Templates for creating styled string using ANSI Escape Sequences
+/
module utils.colorstr;

import std.conv,
			 std.traits;

/// Colors
public{
	enum ubyte BLACK = 30; /// Black
	enum ubyte RED = 31; /// Red
	enum ubyte GREEN = 32; /// Green
	enum ubyte YELLOW = 33; /// Yellow
	enum ubyte BLUE = 34; /// Blue
	enum ubyte MAGENTA = 35; /// Magenta
	enum ubyte CYAN = 36; /// Cyan
	enum ubyte GRAY_LIGHT = 37; /// Light Gray
	enum ubyte GRAY = 90; /// Gray
	enum ubyte RED_LIGHT = 91; /// Light Red
	enum ubyte GREEN_LIGHT = 92; /// Light Green
	enum ubyte YELLOW_LIGHT = 93; /// Light Yellow
	enum ubyte BLUE_LIGHT = 94; /// Light Blue
	enum ubyte MAGENTA_LIGHT = 95; /// Light Magenta
	enum ubyte CYAN_LIGHT = 96; /// Light Cyan
	enum ubyte WHITE = 97; /// White
	enum ubyte BOLD = 1; /// Bold text
	enum ubyte FAINT = 2; /// Faint text
	enum ubyte ITALIC = 3; /// Italic text
	enum ubyte ULINE = 4; /// Underlined text
}

/// Colorized/styled string
/// Can be used with 2, 3, 4 parameters:
/// Params:
/// 1. the string
/// 2. the style (BOLD/FAINT/ITALIC/ULINE) or Foreground color.
/// 3. (optional) is Background color. When present, param2 can be set to `0`
///		for default
/// 4. (optional) the style (BOLD/FAINT/ITALIC/ULINE) or Foreground color
public string style(S)(S s, ubyte f) pure if (isSomeString!S){
	return "\x1b[" ~ f.to!string ~ "m" ~ s ~ "\x1b[0m";
}

/// ditto
public string style(S)(S s, ubyte f, ubyte b) pure if (isSomeString!S){
	if (b < 5){
		if (f == 0)
			return "\x1b[" ~ b.to!string ~ "m" ~ s ~ "\x1b[0m";
		return "\x1b[" ~ f.to!string ~ ";" ~ b.to!string ~ "m" ~ s ~ "\x1b[0m";
	}
	if (f == 0)
		return "\x1b[" ~ (b + 10).to!string ~ "m" ~ s ~ "\x1b[0m";
	return "\x1b[" ~ f.to!string ~ ";" ~ (b + 10).to!string ~ "m" ~ s ~
		"\x1b[0m";
}

///
unittest{
	import std.stdio;
	style("Red", RED).writeln;
	style("Underline", ULINE).writeln;
	style("Red on Green", RED, GREEN).writeln;
	style("Underline on Green", ULINE, GREEN).writeln;
	style("Default on Green", 0, GREEN).writeln;
	style("Red on Green Underlined", RED, GREEN, ULINE).writeln;
	style("Red on Green Underlined", ULINE, GREEN, RED).writeln;
}

/// ditto
public string style(S)(S s, ubyte f, ubyte b, ubyte o){
	if (f == 0)
		return "\x1b[" ~ (b + 10).to!string ~ ";" ~ o.to!string ~ "m" ~ s ~
			"\x1b[0m";
	return "\x1b[" ~ f.to!string ~ ";" ~ (b + 10).to!string ~ ";" ~
		o.to!string ~ "m" ~ s ~ "\x1b[0m";
}

/// ditto
public template Style(alias S, ubyte F) if (isSomeString!(typeof(S))){
	enum Style = style(S, F);
}

/// ditto
public template Style(alias S, ubyte F, ubyte B)
	 if (isSomeString!(typeof(S))){
	enum Style = style(S, F, B);
}

/// ditto
public template Style(alias S, ubyte F, ubyte B, ubyte O)
		if (isSomeString!(typeof(S))){
	enum Style = style(S, F, B, O);
}

///
unittest{
	import std.stdio;
	Style!("Red", RED).writeln;
	Style!("Underline", ULINE).writeln;
	Style!("Red on Green", RED, GREEN).writeln;
	Style!("Underline on Green", ULINE, GREEN).writeln;
	Style!("Default on Green", 0, GREEN).writeln;
	Style!("Red on Green Underlined", RED, GREEN, ULINE).writeln;
	Style!("Red on Green Underlined", ULINE, GREEN, RED).writeln;
}
