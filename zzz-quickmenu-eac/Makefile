NAME=zzz-quickmenu
INSTALL_DIRS=~/ftp ~/xonotic-data

MAKEFILE=$(firstword $(MAKEFILE_LIST))
MAKEFILE_DIR=$(dir $(MAKEFILE))
VERSION_MAKEFILE=$(MAKEFILE_DIR)/version.mk
include $(VERSION_MAKEFILE)
QUICKMENU=$(MAKEFILE_DIR)/quickmenu.txt
PK3=$(MAKEFILE_DIR)/$(NAME)$(VERSION).pk3
PACKAGE=$(PK3).serverpackage

.PHONY: all install increase_number clean

all: install
all: increase_number

$(PK3) : $(PACKAGE)
	zip -p $(PK3) $(PACKAGE) $(QUICKMENU)

$(PACKAGE) : $(QUICKMENU)
	echo "EVIL menu!!! " >$(PACKAGE)

install: $(PK3)
	$(foreach d,$(INSTALL_DIRS), rm -f $(d)/$(NAME)*; cp $(PK3) $(d);)
	rm -f $(PK3) $(PACKAGE)

increase_number:
	bash -c 'let num=`echo $(VERSION) | sed -r "s/[^0-9]//g"`+1 ; sed -ri "s/^(VERSION=[^0-9]+)[0-9]+/\1$$num/" $(VERSION_MAKEFILE);'
