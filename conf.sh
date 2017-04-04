#!/bin/sh

PLIST="vim-nox-py2 zsh curl python-pip git build-essential python-pygments sakura i3
nitrogen x11-xserver-utils xbase-clients xorg xdg-user-dirs tmux xcape fluxgui
ranger command-not-found fonts-freefont-ttf libnotify-bin xclip pcmanfm powerline
lxpolkit pulseaudio pasystray pavucontrol network-manager-gnome ctags atom"

fn_zsh()
{
    if [ ! -d ~/.oh-my-zsh ]
    then
        echo "Instalando Oh My ZSH..."
        curl -L http://install.ohmyz.sh | sh
    else
        echo "Oh My ZSH ya instalado."
    fi
    if grep $USER /etc/passwd | grep -vqs zsh
    then
        echo "Instalando ZSH al usuario actual..."
        sudo chsh -s /bin/zsh $USER
    else
        echo "Zsh ya asignado al usuario actual."
    fi
}

fn_sakura()
{
    if ! update-alternatives --query x-terminal-emulator | grep -qs "^Value:.*sakura"
    then
        echo "Estableciendo sakura como terminal predeterminado..."
        sudo update-alternatives --set x-terminal-emulator /usr/bin/sakura
    else
        echo "sakura ya es el terminal predeterminado."
    fi
}

fn_nitrogen()
{
    D=$HOME/.config/nitrogen
    if [ -d "$D" ]
    then
        [ -d "$D.viejo" ] && rm -rf $D.viejo
        mv -f $D $D.viejo
    fi
    mkdir -p $D
    echo "[:0.0]\nfile=$PWD/fondo.jpg\nmode=0\nbgcolor=#000000" > $D/bg-saved.cfg
}

fn_vim()
{
    echo "Post-instalación de plugins de Vim mediante Vundle..."
    vim +PluginInstall +qall
#    echo "** No olvides ejecutar YouCompleteMe.sh **"
}

prefn_i3()
{
    if [ ! -f /etc/apt/sources.list.d/i3wm.list ]
    then
        echo "Activando el repositorio con la última versión de i3wm..."
        echo "deb http://debian.sur5r.net/i3/ $(lsb_release -sc) universe" | sudo tee /etc/apt/sources.list.d/i3wm.list > /dev/null
        sudo apt-get update
        sudo apt --allow-unauthenticated install sur5r-keyring
        sudo apt update
    else
        echo "Repositorio de i3wm ya activado."
    fi
}

prefn_fluxgui()
{
    if [ ! -f /etc/apt/sources.list.d/nathan-renniewaldock-ubuntu-flux-$(lsb_release -sc).list ]
    then
        echo "Activando el repositorio de xflux..."
        sudo add-apt-repository --yes ppa:nathan-renniewaldock/flux
        sudo apt update
    else
        echo "Repositorio de xflux ya activado."
    fi
}

prefn_atom()
{
    if [ ! -f /etc/apt/sources.list.d/webupd8team-ubuntu-atom-$(lsb_release -sc).list ]
    then
        echo "Activando el repositorio de Atom..."
        sudo add-apt-repository --yes ppa:webupd8team/atom
        sudo apt update
    else
        echo "Repositorio de Atom ya activado."
    fi
}

git submodule update --init --recursive

P=""

for p in $PLIST
do
    if ! dpkg -s $p > /dev/null 2>&1
    then
        P="$p $P"
    fi
done

for p in $PLIST
do
    if type prefn_$p | grep -q "is a shell function" > /dev/null
    then
        eval prefn_$p
    fi
done

if [ -n "$P" ]
then
    echo "Instalando paquetes..."
    sudo apt install -y $P
else
    echo "Paquetes ya instalados."
fi

nombre_paquete()
{
    echo -n "$1"
    [ -n "$2" ] && echo -n " versión $2 ó superior"
}

paquete_local()
{
    COND=""

    if [ -n "$2" ]
    then
        ! dpkg -s $1 > /dev/null 2>&1 || ( ! dpkg -s $1 2> /dev/null | grep -qs "^Version: $2" ) && COND="1"
    else
        ! dpkg -s $1 > /dev/null 2>&1 && COND="1"
    fi

    if [ -n "$COND" ]
    then
        echo -n "Instalando paquete "
        nombre_paquete $1 $2
        echo "..."
        if uname -i | grep x86_64 > /dev/null 2>&1
        then
            sudo dpkg -i $1_*_amd64.deb
        else
            sudo dpkg -i $1_*_i386.deb
        fi
        sudo apt -fy install
    else
        nombre_paquete $1 $2
        echo " ya instalado."
    fi
}

for p in $PLIST
do
    if type fn_$p | grep -q "is a shell function" > /dev/null
    then
        eval fn_$p
    fi
done

FONTS_DIR=~/.local/share/fonts

echo "Instalando tipografía Input Mono..."
mkdir -p $FONTS_DIR
cp -f InputMono/*.ttf $FONTS_DIR
fc-cache -f $FONTS_DIR

for f in $FONTS_DIR/*Powerline*
do
    if [ ! -e "$f" ]
    then
        echo "Instalando tipografías Powerline..."
        ACTUAL=$PWD
        cd powerline-fonts
        ./install.sh
        cd $ACTUAL
    else
        echo "Tipografías Powerline ya instaladas."
    fi
    break
done

echo "Creando enlaces..."

backup_and_link()
{
    if [ -d ~/$1 ]
    then
        [ -d ~/$1.viejo ] && rm -rf ~/$1.viejo
        mv -f ~/$1 ~/$1.viejo
    fi
    if [ -n "$2" ]
    then
        ln -sf $PWD/$2 ~/$1
    else
        ln -sf $PWD/$1 ~/$1
    fi
}

backup_and_link .zshrc
backup_and_link .vimrc
backup_and_link .gvimrc
backup_and_link .vim
backup_and_link .tmux.conf
backup_and_link .dircolors
backup_and_link .less
backup_and_link .lessfilter
[ -d ~/.config ] || mkdir ~/.config
backup_and_link .config/sakura sakura
backup_and_link .config/dunst dunst
backup_and_link .i3

[ -d ~/.local/bin ] || mkdir -p ~/.local/bin

local_bin()
{
    if [ ! -f ~/.local/bin/$1 ]
    then
        echo "Instalando $1..."
        cp $1 ~/.local/bin/$1
    else
        echo "$1 ya instalado."
    fi
}

local_bin unclutter
local_bin lesscurl
local_bin proyecto.sh

eval fn_vim

echo "** Ejecuta git-config.sh para configurar git **"

