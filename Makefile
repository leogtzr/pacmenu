LIBDIR=/usr/local/lib
SH_PATH=/usr/local/bin
VERSION=1.1

all: test
	@echo ""
	@echo "If no error, run make -B install as root"

help:
	@echo ""
	@echo "Usage: make [test|install|uninstall]"
	@echo ""
	@echo "Try make test. If everything is ok, run make -B install as root"
	@echo ""
	@echo "You can remove installation using make uninstall as root"
	@echo ""

install:
	@echo "Install..."
	install -m666 simple_curses.sh $(LIBDIR)/simple_curses.sh
	install -m655 paquetes.sh $(SH_PATH)/paquetes.sh || echo -e "Run as root"
	@echo ".... done"
	
uninstall:
	@echo "Removing library"
	rm -rf $(LIBDIR)/simple_curses.sh
	rm -rf $(SH_PATH)/paquetes.sh || echo -e "Run as root"
	@echo "done"

test:
	@echo "Check if dmenu,pacman is installed"
	which pacman &> /dev/null && echo -e "\033[32mpacman found\033[0m" || echo -e "\033[33mpacman ....... not found\033[0m"
	which dmenu &> /dev/null && echo -e "\033[32mdmenu found\033[0m" || echo -e "dmenu ....... not found";
	@echo "Done."

dist:
	mkdir ./pacmenu-$(VERSION)
	cp LICENSE README AUTHORS INSTALL simple_curses.sh paquetes.sh Makefile ./pacmenu-$(VERSION)
	tar cvfz pacmenu-$(VERSION).tar.gz ./pacmenu-$(VERSION)
	rm -rf ./pacmenu-$(VERSION)
	@echo "pacmenu-$(VERSION).tar.gz done"
