## README

### What is this repository for? ###

This is a VHDL repository containing some avalon bus components (vendor independent) 

 * [Avalon System Identification](./doc/avl_version.md)
 * [Avalon Interrupt controller](./doc/avl_irq.md)
 * [Avalon Bus Splitter](./doc/avl_bus_splitter.md) 

### How do I get set up?/How to run tests ###

Requirements
  * Python >= 3.7
  * vunit_hdl
  * ghdl/Modelsim

#### Arch Linux/Manjaro ####
``` 
sudo pacman -S python python-pip
sudo pacman -S ghdl-gcc gcovr
pip install vunit_hdl
python ./run.py -p6
```

#### Debian/Ubuntu ####
``` 
sudo apt-get install python3 python3-pip
sudo apt-get install ghdl gtkwave gcovr
pip install vunit_hdl
python ./run.py -p6
```

#### Windows ####
Your best bet is probably using Windows Subsystem for Linux and use instructions above. If that is not possible for you: 

install python >= 3.7 (i. e. Anaconda)

Install Modelsim Intel Starter Edition or GHDL

Add both to your PATH environment variable.

Start powershell and run 
```
pip install vunit_hdl
```
afterwards you can start simulation by running
```
python ./run.py -p6
``` 

### Known Issues ###
