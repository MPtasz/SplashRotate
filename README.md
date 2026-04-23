# SplashRotate

![PtaszWare Logo](https://github.com/MPtasz/SplashRotate/blob/main/assets/logos/PtasWareLogo190x197.png)

**PtaszWare**

-  by: Mark Ptaszynski
-  Copyright: March, 2026
-  Version: 1.1.0

---

EdgeTX allows a splash screen ('splash.png' in the SD Card 'images' folder) to be displayed on radio powerup.
This script allows the user to rotate between multiple splash screens that are named 'splashxx.png' where
'xx' is any 2 digit number.

For example: if the user had 10 different splash screens (in the 'images' folder on the SD card) named 'splash01.png'
thru 'splash10.png', running the script 'SplashRotateLua' will copy 'splash01.png' to 'splash.png' (this will then be the next splash screeen to
be displayed on the next powerup). 'splash01.png' is then renamed to highest number + 1. In this example it
will be renamed 'splash11.png'. (The lowest number splash screen will become the next 'splash.png' and the lowest
splash screen will then be renamed to the higest number +1.)

## INSTALLATION

Copy the SplashRotate.lua file to /SCRIPTS/TOOLS/SplashRotate.lua  (on the radio's SD card).
The 'TOOLS' menu will now have a 'SplashRotate' button, click the button to run the script.

## USAGE

Radio Menu → Tools → SplashRotate

![Tools/SplashRotate](https://github.com/MPtasz/SplashRotate/blob/main/assets/ScreenShots/ToolsSplashRotate.png)

  - click the 'SplashRotate' button to run the script
  - after a breif 'Loading...' screen the the script will display the following screen.
  
![Tools/SplashRotate](https://github.com/MPtasz/SplashRotate/blob/main/assets/ScreenShots/SplashRotateDisplay.png)  
  
  - the 'Active' file name is the file that is the current splash screen
  - the 'Archive' number is the total number of splash screens in the rotatioon
  - the 'Highest' number is the number of the highest splash screen
  - the 'Highest' number is increased by 1 every time the scrip is run
  - if the splaash files are named 'splash01.png' thru 'splash10.png' and the 'SplashRotate' script is run, the files
  will then be named 'splash02.png' thru 'splash11.png'. This rotation continues each time the 'SplashRotate' script is run.
  The highest number that the scripty can use is 999. The rotation number sshould be reset before this number is reached
  
![Tools/SplashRotate](https://github.com/MPtasz/SplashRotate/blob/main/assets/ScreenShots/SplashRotateArchiveDisplay.png)     
  
  - press SAVE to write changes to the SD card
  
![Tools/PilotInfo](https://github.com/MPtasz/PilotInfo/blob/main/assets/screenshots/PilotInfoSaved.png)     
  
  - press the EdgeTX logo (top-left) or CLOSE to exit
  - if there are unsaved changes a prompt will ask to confirm
