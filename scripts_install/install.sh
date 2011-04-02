#!/bin/bash
#
# To install you need to execute with 'sudo'.
#

admin_email="ulissesmonhecosta@gmail.com"

function install_package {
	case `uname -s` in
		"Darwin")
			install_macosx
			;;
		"Linux")
			case `uname -v` in
				*"Ubuntu"*)
					install_ubuntu
					;;
				*)
					echo "Your Linux is not supported yet. If it does have a packet manager please send an email to $admin_email"
					exit 1;
					;;
				esac
			;;
		*)
			echo "Your operative system is not supported yet. Please send an email to $admin_email"
			exit 1;
			;;
	esac
}

function install_macosx {
	port install gd2
	install_perl_modules
}

function install_ubuntu {
	install_aptitude_modules libgd-dev
	install_perl_modules
}

function install_aptitude_modules {
	for pkg in $@; do
		dpkg -s $pkg
		if [ $? -eq 0 ]; then
			echo "module $pkg installed"
		else
			echo "module $pkg not installed, installing..."
			aptitude --assume-yes install $pkg
		fi
	done;
}

function install_perl_modules {
	perl -MCPAN -e '$CPAN->{prerequisites_policy}=follow'
	local packages=(Makefile::Parser Parse::Yapp  GD GD::Graph GD::Graph::bars GD::Graph::pie Path::Class
	          Moose Term::ReadLine Term::ReadLine::Gnu Digest::SHA DBIx::Class Data::Dumper)
	
	if_not_exist_install_perl_modules ${packages[@]}
}

function if_not_exist_install_perl_modules {
	local packages=()
	
	for module in $@; do
		is_perl_module_installed $module
		if [ $? -eq 1 ]; then
			echo "$module installed";
		else
			echo "$module not installed, installing...";
			packages[$[${#packages[@]}+1]]=$module;
		fi
	done;
	
	EXEC="cpan -if ${packages[@]}"
	$EXEC
}

function is_perl_module_installed {
	if [ -z "`perl -M$1 -e 1 2>&1`" ]; then
		return 1;
	else
		return 0;
	fi
}

function check_user_id {
	if [ ! "`whoami`" = "root" ]; then
		echo "Not running as root. Yes this is an installation file..."
		exit 1 ;
	fi
}

check_user_id
install_package

exit 0;

