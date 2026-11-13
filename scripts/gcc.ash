



void main() {
	print(get_property("commandLineNamespace"));
	set_property("commandLineNamespace", "");
	cli_execute("using smmUnrestricted.ash");
	cli_execute("using smmEcon.ash");
}
