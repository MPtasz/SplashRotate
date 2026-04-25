-- TNS|SplashRotate V2.3|TNE
--
-- =============================================================================
--
--  ____  _                __        __                
-- |  _ \| |_ __ _ __  ____\ \      / /__ _ _ __ ___  
-- | |_) | __/ _` / __|_  / \ \ /\ / / _` | '__/ _ \ 
-- |  __/| || (_| \__ \/ /   \ V  V / (_| | | |  __/ 
-- |_|    \__\__,_|___/___|   \_/\_/ \__,_|_|  \___|
--
--
--  PtaszWare
--  by: Mark Ptaszynski
--  Copyright: March, 2026
--  Version: 2.3.0
--
-- =============================================================================
--
-- License GPLv3: http://www.gnu.org/licenses/gpl-3.0.html
--
-- This program is free software: you can redistribute it and/or modify it under
-- the terms of the GNU General Public License as published by the Free Software
-- Foundation, either version 3 of the License, or (at your option) any later
-- version.
--
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY
-- WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
-- A PARTICULAR PURPOSE. See the GNU General Public License for more details.
--
-- =============================================================================
-- SplashRotateV23.lua  v2.3.0
--
-- Rotation: shift-all-down by one using one temp file.
--
--   splash01 --> splashtmp
--   splash02 --> splash01
--   splash03 --> splash02
--   splash04 --> splash03
--   
--   this continues until the highest number is reached
--
--   then splashtmp --> splash
--
-- State machine phases (in order):
--   "scan"    Scan for highest numbered file; validate preconditions.
--   "temp"    Copy splash01 -> splash_tmp; delete splash01.
--   "shift"   One run() per shift: splash(shiftN+1) -> splash(shiftN).
--   "demote"  Move splash.png -> splash(highest).
--   "promote" Move splash_tmp -> splash.png.  Done; build results page.
--   "error"   Any phase can jump here; sets statusTxt and falls to "done".
--   "done"    Build file list, call showPage1(), stop.
--
-- Place in /SCRIPTS/TOOLS/. Run from EdgeTX Tools menu.
-- EdgeTX 2.11+
-- EdgeTX Lua Reference 5.3
-- =============================================================================
 
local IMG_DIR     = "/images"
local BASE        = "splash"
local EXT         = ".png"
local MAX_N       = 999
 
local PAGE1_FILES = 3
local PAGE2_FILES = 7
 
local BTN_Y   = 7
local LABEL_Y = 48
 
local exitApp = false
 
local rotateOk  = false
local statusTxt = ""
local fileList  = {}
 
local phase   = "scan"
local highest = 0
local hasBase = false
local shiftN  = 1
 
local spinChars = { "|", "/", "-", "\\" }
local spinIdx   = 1
 
local statusLbl = nil   -- updated each frame during rotation
local exitLbl   = nil   -- set once if Close/Back pressed during rotation
 
local function imgPath(n)
  if n == 0 then
    return IMG_DIR .. "/" .. BASE .. EXT
  end
  return IMG_DIR .. "/" .. BASE .. string.format("%02d", n) .. EXT
end
 
local tmpPath = IMG_DIR .. "/splash_tmp" .. EXT
 
local function exists(path)
  return fstat(path) ~= nil
end
 
-- ---- file I/O --------------------------------------------------------------
 
local function copyFile(src, dst)
  local inF = io.open(src, "r")
  if not inF then return false, "cannot open " .. src end
  local outF = io.open(dst, "w")
  if not outF then
    io.close(inF)
    return false, "cannot create " .. dst
  end
  while true do
    local data = io.read(inF, 256)
    if data == nil or data == "" then break end
    io.write(outF, data)
  end
  io.close(inF)
  io.close(outF)
  return true, nil
end
 
local function renameFile(src, dst)
  local ok, err = copyFile(src, dst)
  if not ok then
    del(dst)
    return false, err
  end
  del(src)
  return true, nil
end
 
-- ---- spinner ---------------------------------------------------------------
 
local function spin()
  spinIdx = (spinIdx % #spinChars) + 1
  return spinChars[spinIdx]
end
 
-- ---- file list -------------------------------------------------------------
 
local function buildFileList()
  local list = {}
  if exists(imgPath(0)) then
    list[#list + 1] = { label = "splash.png  [ACTIVE - shown on boot]" }
  end
  for n = 1, MAX_N do
    if exists(imgPath(n)) then
      local tag = (n == 1) and "  <- promoted next run" or ""
      list[#list + 1] = { label = BASE .. string.format("%02d", n) .. EXT .. tag }
    else
      break
    end
  end
  return list
end
 
-- ---- page count -----------------------------------------------------------
 
local function totalPageCount(numFilesCount)
  if numFilesCount <= PAGE1_FILES then return 1 end
  return 1 + math.ceil((numFilesCount - PAGE1_FILES) / PAGE2_FILES)
end
 
local showPage1, showPage2
 
showPage1 = function()
  local numFiles = {}
  for i = 2, #fileList do
    numFiles[#numFiles + 1] = fileList[i]
  end
  local hasPage2  = (#numFiles > PAGE1_FILES)
  local totalPages = totalPageCount(#numFiles)
 
  local pg = lvgl.page({
    title    = "Splash Rotator  v2.3",
    subtitle = (rotateOk and "Rotation complete" or "Error") ..
               "  -  Page 1 of " .. totalPages,
    back     = function() exitApp = true end,
  })
 
  pg:button({
    x     = 10,
    y     = BTN_Y,
    w     = 100,
    text  = "Close",
    press = function() exitApp = true end,
  })
  if hasPage2 then
    pg:button({
      x     = 120,
      y     = BTN_Y,
      w     = 110,
      text  = "Next ->",
      press = function() showPage2(numFiles, PAGE1_FILES + 1) end,
    })
  end
 
  local lines = {}
  local s = statusTxt
  local nl = string.find(s, "\n")
  if nl then
    lines[#lines + 1] = string.sub(s, 1, nl - 1)
    lines[#lines + 1] = string.sub(s, nl + 1)
  else
    lines[#lines + 1] = s
  end
  -- File queue -----------------------------------------------------------
  lines[#lines + 1] = "File queue (" .. #fileList .. " files  in  " .. IMG_DIR .. "):"
  if fileList[1] then
    lines[#lines + 1] = "  " .. fileList[1].label
  end
  for i = 1, math.min(PAGE1_FILES, #numFiles) do
    lines[#lines + 1] = "  " .. numFiles[i].label
  end
  if hasPage2 then
    lines[#lines + 1] = "  ...and " .. (#numFiles - PAGE1_FILES) .. " more  (press Next ->)"
  end
 
  pg:label({
    x    = 10,
    y    = LABEL_Y,
    text = table.concat(lines, "\n"),
  })
end
 
showPage2 = function(numFiles, startIdx)
  local prevStart = startIdx - PAGE2_FILES
  local endIdx    = startIdx + PAGE2_FILES - 1
  local hasNext   = (endIdx < #numFiles)
 
  local backPress
  if prevStart <= PAGE1_FILES then
    backPress = function() showPage1() end
  else
    backPress = function() showPage2(numFiles, prevStart) end
  end
 
  local totalPages = totalPageCount(#numFiles)
  local pageNum    = 2 + math.floor((startIdx - PAGE1_FILES - 1) / PAGE2_FILES)
 
  local pg = lvgl.page({
    title    = "Splash Rotator  v2.3",
    subtitle = "File queue  -  Page " .. pageNum .. " of " .. totalPages,
    back     = backPress,
  })
 
  pg:button({
    x     = 10,
    y     = BTN_Y,
    w     = 100,
    text  = "<- Back",
    press = backPress,
  })
  if hasNext then
    pg:button({
      x     = 120,
      y     = BTN_Y,
      w     = 100,
      text  = "Next ->",
      press = function() showPage2(numFiles, startIdx + PAGE2_FILES) end,
    })
    pg:button({
      x     = 230,
      y     = BTN_Y,
      w     = 100,
      text  = "Close",
      press = function() exitApp = true end,
    })
  else
    pg:button({
      x     = 120,
      y     = BTN_Y,
      w     = 100,
      text  = "Close",
      press = function() exitApp = true end,
    })
  end
 
  local lines = {}
  local shown = 0
  for i = startIdx, #numFiles do
    if shown >= PAGE2_FILES then break end
    lines[#lines + 1] = "  " .. numFiles[i].label
    shown = shown + 1
  end
  if hasNext then
    local remaining = #numFiles - (startIdx + PAGE2_FILES - 1)
    lines[#lines + 1] = "  ...and " .. remaining .. " more  (press Next ->)"
  end
 
  pg:label({
    x    = 10,
    y    = LABEL_Y,
    text = table.concat(lines, "\n"),
  })
end
 
-- ---- LVGL init -------------------------------------------------------------
-- Returns almost instantly. Button created first, then the status label.
-- EdgeTX renders this frame before run() is called, so "Scanning files..."
-- appears before any blocking I/O begins.
 
local function init()
  if lvgl == nil then return end
 
  local pg = lvgl.page({
    title    = "Splash Rotator  v2.3",
    subtitle = "Working...",
    back     = function()
      exitApp = true
      exitLbl:set({ text = "Closing after rotation..." })
    end,
  })
 
  pg:button({
    x     = 10,
    y     = BTN_Y,
    w     = 120,
    text  = "Close",
    press = function()
      exitApp = true
      exitLbl:set({ text = "Closing after rotation..." })
    end,
  })
 
  -- Sits to the right of the Close button; never overwritten by run()
  exitLbl = pg:label({
    x    = 140,
    y    = BTN_Y + 8,
    text = "",
  })
 
  statusLbl = pg:label({
    x    = 10,
    y    = LABEL_Y,
    text = "Scanning files...  |",
  })
end
 
-- ---- run -------------------------------------------------------------------
 
local function run(event, touchState)
  if lvgl == nil then
    lcd.clear()
    lcd.drawText(10, 20, "Splash Rotator v2.3", MIDSIZE)
    lcd.drawText(10, 50, "Requires EdgeTX 2.11+", 0)
    if event == EVT_VIRTUAL_EXIT then return 2 end
    return 0
  end
 
  if phase == "scan" then
    hasBase = exists(imgPath(0))
    highest = 0
    for n = 1, MAX_N do
      if exists(imgPath(n)) then highest = n else break end
    end
    if not hasBase and highest == 0 then
      statusTxt = "ABORT: no splash files found in " .. IMG_DIR
      phase = "error"
    elseif highest == 0 then
      statusTxt = "Only splash.png present.\nAdd splash01.png etc. to enable cycling."
      phase = "error"
    elseif highest >= MAX_N then
      statusTxt = "ABORT: ceiling reached (splash" .. MAX_N .. ".png exists)."
      phase = "error"
    else
      statusLbl:set({
        text = "Saving splash01.png  " .. spin() .. "\n" ..
               highest .. " files to process...",
      })
      phase = "temp"
    end
 
  elseif phase == "temp" then
    local ok, err = copyFile(imgPath(1), tmpPath)
    if not ok then
      del(tmpPath)
      statusTxt = "ERR saving temp: " .. err
      phase = "error"
    else
      del(imgPath(1))
      shiftN = 1
      if highest > 1 then
        statusLbl:set({
          text = "Shifting files...  " .. spin() .. "\n" ..
                 "Step 1 of " .. (highest - 1) .. "  (splash02 -> splash01)",
        })
        phase = "shift"
      else
        statusLbl:set({ text = "Demoting splash.png  " .. spin() })
        phase = "demote"
      end
    end
 
  elseif phase == "shift" then
    local ok, err = renameFile(imgPath(shiftN + 1), imgPath(shiftN))
    if not ok then
      del(tmpPath)
      statusTxt = "ERR shifting splash" ..
                  string.format("%02d", shiftN + 1) .. ": " .. err
      phase = "error"
    else
      shiftN = shiftN + 1
      if shiftN <= highest - 1 then
        local fromName = BASE .. string.format("%02d", shiftN + 1) .. EXT
        local toName   = BASE .. string.format("%02d", shiftN)     .. EXT
        statusLbl:set({
          text = "Shifting files...  " .. spin() .. "\n" ..
                 "Step " .. shiftN .. " of " .. (highest - 1) ..
                 "  (" .. fromName .. " -> " .. toName .. ")",
        })
      else
        statusLbl:set({ text = "Demoting splash.png  " .. spin() })
        phase = "demote"
      end
    end
 
  elseif phase == "demote" then
    if hasBase then
      local ok, err = renameFile(imgPath(0), imgPath(highest))
      if not ok then
        del(tmpPath)
        statusTxt = "ERR demoting splash.png: " .. err
        phase = "error"
      else
        statusLbl:set({ text = "Promoting new active splash  " .. spin() })
        phase = "promote"
      end
    else
      statusLbl:set({ text = "Promoting new active splash  " .. spin() })
      phase = "promote"
    end
 
  elseif phase == "promote" then
    local ok, err = renameFile(tmpPath, imgPath(0))
    if not ok then
      statusTxt = "ERR promoting new active: " .. err
      phase = "error"
    else
      rotateOk = true
      local promoted    = BASE .. string.format("%02d", 1) .. EXT
      local demotedSlot = string.format("%02d", highest)
      statusTxt = "Promoted: " .. promoted .. "  ->  splash.png\n" ..
                  "Demoted:  splash.png  ->  splash" .. demotedSlot .. ".png"
      phase = "done"
    end
 
  elseif phase == "error" then
    rotateOk = false
    phase = "done"
 
  elseif phase == "done" then
    fileList = buildFileList()
    if exitApp then
      return 2   -- Close was pressed during rotation; exit cleanly, skip results
    end
    showPage1()
    phase = "idle"
  end
 
  -- Only honour exitApp on the results pages (phase == "idle").
  -- During rotation phases the flag is set but deferred (see "done" above).
  if phase == "idle" and exitApp then return 2 end
  return 0
end
 
return { init = init, run = run, useLvgl = true }