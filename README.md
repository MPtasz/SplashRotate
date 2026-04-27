# SplashRotate

![PtaszWare Logo](https://github.com/MPtasz/SplashRotate/blob/main/assets/logos/PtasWareLogo190x197.png)

**PtaszWare**

-  by: Mark Ptaszynski
-  Copyright: March, 2026
-  Version: 2.3.0

---

EdgeTX allows a splash screen ('splash.png' in the SD Card 'images' folder) to be displayed on radio boot/powerup.
This script allows the user to rotate between multiple splash screens that are named 'splashxx.png' where
'xx' is any 2 digit number. (Note: The script will continue to work up to a rotation number of 999.
Any file number beyond 999 will be ignored.) The script works with contiguous numbered splash files. If
there is a gap in the numbering sequence processing stops at the gap and any further files are ignored.

## Environment

  - Radio Master TX16S MK2 with a color display of 480 x 272
  - EdgeTX 2.11+ using LVGL
  - EdgeTX Lua Reference 5.3

## Example Rotation

If the user has 10 different splash screens (in the 'images' folder on the SD card) named 'splash01.png'
thru 'splash10.png', running the script 'SplashRotateV23.lua' will simply rotate thru the files.
All file names will be demoted by one number and the current 'splash.png' will move to 'splash10.png'.

## Installation

Copy the 'SplashRotateV23.lua' file into /SCRIPTS/TOOLS/ directory on the radio's SD card.
The 'TOOLS' menu will now have a 'SplashRotate V2.3' button.

## Usage

Radio Menu → Tools → SplashRotate V2.3

![Tools/SplashRotate](https://github.com/MPtasz/SplashRotate/blob/main/assets/ScreenShots/ToolsSplashRotate.png)

  - Click the 'SplashRotate V2.3' button to run the script.
     
![Tools/SplashRotate](https://github.com/MPtasz/SplashRotate/blob/main/assets/ScreenShots/SplashRotateWorking.png)  

  - You will then see the 'Working' screen.
  - It lets you know the splash files are being shifted (rotated).
  - It shows you what splash file is currently being shifted and what it is being shifted to.
  - It also shows you the total number of splash files - this process can take a few minutes when you have a large number
  of splash files to shift.
  
![Tools/SplashRotate](https://github.com/MPtasz/SplashRotate/blob/main/assets/ScreenShots/RotationComplete.png)    

  - When shifting is complete the summary page will be displayed. It shows what files were shifted and the total number
  of files processed.
  - The 'Close' button will end the script take you back to the 'Tools' menu.
  - The 'View Splash ->' button will display the splash screen that will be displayed the next time the radio is booted/powered up.  
  
![Tools/SplashRotate](https://github.com/MPtasz/SplashRotate/blob/main/assets/ScreenShots/NextSplash.png)  
 
![Tools/SplashRotate](https://github.com/MPtasz/SplashRotate/blob/main/assets/ScreenShots/SplashRotateWorkingClose.png)  

  - If you press the 'Close' button on the 'Working' screen while the files are still being shifted, the script will finish
  shifting all the files, then immediately close after the shifting process is complete, without displaying any summary page
  and display the message 'Closing after rotation...'.

## License

 GPLv3: http://www.gnu.org/licenses/gpl-3.0.html

 This program is free software: you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation, either version 3 of the License, or (at your option) any later
 version.

 This program is distributed in the hope that it will be useful, but WITHOUT ANY
 WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 A PARTICULAR PURPOSE. See the GNU General Public License for more details.  
  

