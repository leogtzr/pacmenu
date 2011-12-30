#!/bin/bash
#===============================================================================
#
#          FILE:  paquetes.sh
# 
#         USAGE:  ./paquetes.sh -h 
# 
#   DESCRIPTION: An interactive menu to delete, query, and update packages... 
# 
#  REQUIREMENTS:  dmenu, pacman
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR: Leo Gutiérrez R. leogutierrezramirez@gmail.com (2011), 
#===============================================================================

LIBDIR=/usr/local/lib
export LIBDIR

temp=$*

checkOptions()
{
	args=`getopt cdih $temp 2> /dev/null`
	[ $? != 0 ] && {
		usage;
		exit 1;
	}

	count=0

	set -- $args
	for i
	do
		case "$i" in
			-c) 
				shift;
				((count++));
				shift;
				;;
			-d)
				shift;			
				((count++));
				shift;
				;;
			-i)
				shift;
				((count++));
				shift;
				
			;;
			-h)
				shift;
				((count++));
				shift;
				;;
			*)
				[ $count -eq 0 ] && {
					usage;
					exit 1;
				}
				break;
		esac
	done
}

viewdependencies()
{
	name="$1"
	n_dependencies=$(pacman -Qi "$1" | grep ^Depends* | sed "s/.*:\s\(.*\)$/\1/g" | wc -w);
	echo -e "Dependencies [$n_dependencies]: " > ./temp_file
	pacman -Qi "$name" | grep ^Depends* | sed "s/.*:\s\(.*\)$/\1/g" | tr ' ' '\n' | grep -v ^$ >> ./temp_file
	main()
	{
		window "$name - $(pacman -Qi "$name" | grep ^Version* | awk '{print $3}')" red
		append_file ./temp_file
		addsep
		endwin
	}
	showWindow;
	# Borrar buffer...
	rm -rf ./temp_file
	on_kill;
	read -p "Press ENTER key to continue" dummy
	
}

list()
{
	pacman -Qi | grep ^Name* | awk '{print $3}'
}

numerate()
{
	list | grep -n "^${1}$" | cut -f1 -d':'
}

exists()
{
	pacman -Qi "$1" &> /dev/null && return 0 || return 1
}

count()
{
	pacman -Qi | grep ^Name* | wc -l
}

getch()
{  
	OLD_STTY=`stty -g`  
	stty cbreak -echo  
	GETCH=`dd if=/dev/tty bs=1 count=1 2>/dev/null`  
	stty $OLD_STTY  
}   
	
showWindow()
{
	term_init
	init_chars
	tput cup 0 0 >> $BUFFER
	tput il $(tput lines) >>$BUFFER
	main >> $BUFFER 
	refresh
}

showPackage()
{
	pacman -Qi "$1" > temp_file
	echo -e "`numerate "$1"` of `count` packages" >> temp_file
	
	name="$1"			

	source $LIBDIR/simple_curses.sh
	main()
	{
		window "$name - $(pacman -Qi ${name} | grep ^Version* | awk '{print $3}')" red
		append_file ./temp_file
		addsep
		append "[D]elete | [U]pdate | [B]ack to menu | [V]iew dependencies | [Q]uit        (ESC in the menu to exit)"
		endwin
	}
	
	showWindow;
	# Borrar buffer...
	rm -rf ./temp_file
	on_kill;

}

usage()
{
		
	source $LIBDIR/simple_curses.sh
	
cat <<EOF>USO

paquetes.sh [OPTION] ... [PACKAGE]

Options : 

-c 	        : Count packages.
-d [package] : Delete package.
-i [package] : Interactive menu.
-h : Show this help.

Author:
Leo Gutierrez Ramirez.
leogutierrezramirez@gmail.com
EOF
	
	main()
	{
		window "Usage" green
		append_file ./USO
		endwin
	}
	
	showWindow;
	rm -f ./USO &> /dev/null	
}

menu()
{
	# Encerramos al usuario en un bucle hasta que nos dé un paquete que exista.
		while [[ 1 ]];
		do
			package=`pacman -Qi | grep ^Name.* | awk '{print $3}' | dmenu -l 30 -p "Package : "`
			[ "$package" ] || {
				echo -e "Exiting...";
				exit 0;	
			}
			# Comprobar que exista el paquete...
			exists "$package" && break;
		done
			
		# Nosquedamos dentro del bucle a menos que teclee "b" ó "q"
		while [ "$GETCH" != "b" -o "$GETCH" != "q" ]
		do
			showPackage "$package"
			getch;
				
			# Casear las opciones;
			case "$GETCH" in
				"b"|"B")
				# Lo mismo...
					while [[ 1 ]];
					do
						package=`pacman -Qi | grep ^Name.* | awk '{print $3}' | dmenu -l 30 -p "Package : "`
						# Comprobamos que exista...
						exists "$package" && break;
					done
						# Si pulsó ESC salimos del programa.
						[ "$package" ] || {
							echo -e "Exiting...";
							exit 0;
						}
						# Sino mostramos el paquete
					showPackage "$package";
					;;
				"q"|"Q") # Salimos...
					echo -e "Exiting...";
					exit 0;
					;;
				"u"|"U") # Actualizamos...
					sudo pacman -S "$package" --noconfirm || {
							echo -e "$(tput setaf 1)Error updating package.$(tput sgr0)";
							exit 1;
						}
					;;
				"d"|"D")
					
					sudo pacman -R "$package" --noconfirm || {
						echo -e "$(tput setaf 1)Error removing package.$(tput sgr0)";
						exists "$1" || echo -e "$(tput setaf 1)$(tput bold)$1 not found$(tput sgr0)";
						getch;

						exit 1;
					}
					
					clear;
					while [[ 1 ]];
					do
						package=`pacman -Qi | grep ^Name.* | awk '{print $3}' | dmenu -l 30 -p "Package : "`
						[ "$package" ] || {
								echo -e "Exiting...";
								exit 0;	
						}
						exists "$package" && break;
					done

					[ "$package" ] || {
						echo -e "Exiting...";
						exit 0;	
					}

					;;
					
				"v"|"V")
						viewdependencies "$package"
						;;
					
				"h"|"H")
					usage;
					exit 0;
					;;
						
				*)
					:
					;;
			esac
		done
			
}


checkOptions;

if [ $count -gt 1 ]
then
	echo -e "Error, varias opciones  -> `basename $0` -h for help.";
	exit 1;
fi

args=`getopt hcdi $* 2> /dev/null`
[ $? != 0 ] && {
	usage;
	exit 1;
}

set -- $args
for i
do
  case "$i" in
        -c) # Count packages.
        
        shift;
        
		n_packages=$(pacman -Qi | grep ^Name* | wc -l)
		echo -e "$(tput bold)$n_packages paquetes encontrados.$(tput sgr0)";

		break;
        shift;
        ;;
        
        -d) # Delete packages.
        
        shift;
        
        # Checar si hay permisos.
        [ "$UID" -ne 0 ] && {
			echo -e "$(tput setaf 1)You must be root!$(tput sgr0)";
			exit 1;
		}
        
		[ $# -eq 1 ] && {
			usage;
			exit 1;
		}
		
		shift;
		
        echo -e "Removing ... $(tput setaf 2)$1 $(tput sgr0)";
		pacman -Rs "$1" --noconfirm &> /dev/null || {
			echo -e "$(tput setaf 1)Error removing package.$(tput sgr0)";
			exists "$1" || echo -e "$(tput setaf 1)$(tput bold)$1 not found$(tput sgr0)"
			exit 1;
		}
		
		exit 0;
		
		break;
		shift;
        ;;
        
        -h)
			shift;
			usage;
			exit 0;
			shift;
		;;
        
        -i) # Package information
        shift;
		
		if [ "$#" -eq 1 ]
		then
				GETCH=
				menu;
				
		else
			shift;
			
			package="$1"
			exists "$1" || {
				echo -e "$(tput setaf 1)$(tput bold)$1 not found$(tput sgr0)"
				exit 1;
			}
			
			while [ "$GETCH" != "b" -o "$GETCH" != "q" ]
			do
				showPackage "$package"
				getch;
				
				# Casear las opciones;
				case "$GETCH" in
					"b"|"B")
						#package=`pacman -Qi | grep ^Name.* | awk '{print $3}' | dmenu -l 30 -p "Package : "`
						while [[ 1 ]];
						do
							package=`pacman -Qi | grep ^Name.* | awk '{print $3}' | dmenu -l 30 -p "Package : "`
							[ "$package" ] || {
								echo -e "Exiting...";
								exit 0;	
							}

							exists "$package" && break;
						done

						showPackage "$package";
						
						;;
					"q"|"Q")
						echo -e "Exiting...";
						exit 0;
						;;
					"u"|"U")
						
						sudo pacman -S "$package" --noconfirm || {
							echo -e "$(tput setaf 1)Error updating package.$(tput sgr0)";
							exit 1;
						}
						;;
					"d"|"D")
						
						sudo pacman -R "$package" --noconfirm || {
							echo -e "$(tput setaf 1)Error removing package.$(tput sgr0)";
							exit 1;
						}
						clear;
						while [[ 1 ]];
						do
							package=`pacman -Qi | grep ^Name.* | awk '{print $3}' | dmenu -l 30 -p "Package : "`
							[ "$package" ] || {
								echo -e "Exiting...";
								exit 0;	
							}
							exists "$package" && break;
						done
						;;
						
						"v"|"V")
							viewdependencies "$package"
						;;
						
				*)
					echo -e "$(tput setaf 1)Error.$(tput sgr0)";
					;;
			esac
			
			
		done
	
		fi
		
		break;
		shift;
        ;;
        
		*)
			usage;
			exit 1;
			;;
  esac
done
