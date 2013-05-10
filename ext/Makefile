CFLAGS := -fPIC -O3 -g -Wall -Werror 
CC := gcc
MAJOR := 1
MINOR := 0
NAME := lsd
VERSION := $(MAJOR).$(MINOR)

lib: lib$(NAME).$(VERSION).dylib

lib$(NAME).$(VERSION).dylib: $(NAME).o
	$(CC) -dynamiclib -lm -o lib$(NAME).dylib $^ 

clean:
	$(RM) *.o *.so* *.dylib

$(NAME)_test: lib$(NAME).$(VERSION).dylib
	$(CC) lsd_call_example.c -o $@ -L. -l$(NAME)

test: $(NAME)_test
	LD_LIBRARY_PATH=. ./$(NAME)_test
