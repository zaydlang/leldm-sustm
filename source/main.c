#include <stdio.h>

extern int run_test_arm9();

#define NUM_TESTS 18

int main(int argc, char **argv) {
	consoleDemoInit();

	int last_test_ran = run_test_arm9();
	if (last_test_ran != -1) {
		printf("Failed on test #%x\n", last_test_ran);
	} else {
		printf("Good! :)");
	}

	while (1) {}

	return 0;
}