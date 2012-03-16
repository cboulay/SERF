# BCPy2000 modules

I use [BCI2000](www.bci2000.org) for data acquisition and on-line feedback of acquired data. BCI2000 uses modules three:
1. A signal source module
2. A signal processing module
3. An application module

Most source modules generate a generic output (structured data), most processing modules take structured data and output differently-structured data, and then applications vary widely.

Source modules are specific in their input (hardware vendor libraries) but generic in their output (data streams). It is not really necessary for me to write my own signal source module because there are many available for the hardware I want to use and their output is all the same.

My needs for signal processing and application are not so common, so I need my own modules for these. I can write the modules in C++ or I can write the modules in Python and have some pre-existing [BCPy2000 modules](http://www.bci2000.org/wiki/index.php/Contributions:BCPy2000) import my code. I have chosen the latter for rapid prototyping and to ease myself into [BCI2000](www.bci2000.org) programming with a simpler language.

## Signal-processing modules

### HighpassRectify

## Application modules

### ContingentTriggerApplication