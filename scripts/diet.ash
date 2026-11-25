// diet.ash -- the daily diet. See smmDiet.ash for what it does and its options:
//   call diet.ash        print the whole-day plan
//   call diet.ash execute | turngen | finish [yes] [value=N] [budget=N] ...
script "diet";
since r29462;
import <smmDiet.ash>

void main(string args) {
	smmDietMain(args);
}
