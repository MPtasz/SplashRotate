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

  - Click the 'SplashRotate' button to run the script.
  - After a breif 'Loading...' screen the the script will display the following screen.
  - The 'Close' button will end the script and return to the 'Tools' menu'
  
![Tools/SplashRotate](https://github.com/MPtasz/SplashRotate/blob/main/assets/ScreenShots/SplashRotateDisplay.png)  
  
  - The 'Active' file name is the file that is the current splash screen.
  - The 'Archive' number is the total number of splash screens in the rotation.
  - The 'Highest' number is the number of the highest splash screen.
  - The 'Highest' number is increased by 1 every time the script is run.
  - If the splaash files are named 'splash01.png' thru 'splash10.png' and the 'SplashRotate' script is run, the files
  will then be named 'splash02.png' thru 'splash11.png'. This rotation continues each time the 'SplashRotate' script is run.
  The highest number that the script can handle is 999. The rotation number sshould be reset before this number is reached
  by clicking the 'ArchiveCleanup' button.
  - This script will function with any number of splash screens as long as the highest number does not exceed 1000.  
  
![Tools/SplashRotate](https://github.com/MPtasz/SplashRotate/blob/main/assets/ScreenShots/SplashRotateArchiveDisplay.png)     
  
  - Click the 'ArchiveCleanup' button to reset the rotation numbers back to their lowest numbers.
  - for example is there are 10 splash screen files, they will be re-numbered 'splash01.png' thru 'splash10.png'
  after the 'ArchiveCleanup' button is pressed.
  - The 'Renumbered' field tells you how many splash screens are on your radio and what they have been re-numbered to.
  

