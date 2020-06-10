# squeezebox-DisplayTest-Plugin
Steps to install this plugin:

* go to the Logitech Media Server (LMS) base directory
  * in Windows, this is something like C:\Program Files (x86)\Squeezebox\Server
* from there, locate the subdirectory 'slim\plugins' and navigate there
* create a subdirectory named 'DisplayTest' (without the apostrophes)
* navigate to the new subdirectory
* copy all files (install.xml, Plugin.pm, strings.txt) from the GIT repo into the new directory
* restart Logitech Media Server service
* enable the plugin in the LMS settings

To use the plugin:
* navigate to your device's home menu
* locate the Extras entry and select it
* DisplayTest should be in the list that comes up next, often it's the first entry shown
* navigate 'right' or press the PLAY button to start
* the entire display will become white and this is your chance to see traces of burn-in and/or filament starvation as discussed in https://joes-tech-blog.blogspot.com/2017/04/logitech-squeezebox-boom-vfd-display_30.html
* to get back out of this mode, hold 'left' for one or two seconds
