-- TNS|SplashRotate V2.3|TNE
-- =============================================================================
--
--  ____  _                __        __
-- |  _ \| |_ __ _ __  ____\ \      / /_ _ _ __ ___
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
-- Rotation: shift-all-down using one temp file.
--   splash01 -> splash_tmp
--   splash02 -> splash01  ...  splashN -> splash(N-1)
--   splash.png -> splashN
--   splash_tmp -> splash.png
--
-- File browser: one page per file built from run() (never from inside an
-- LVGL event handler).  Button press sets pendingIdx; the next run() call
-- builds the page with lvgl.page() + pg:image().
--
-- Place in /SCRIPTS/TOOLS/.
-- EdgeTX 2.11+
-- =============================================================================
 
local IMG_DIR = "/images"
local BASE    = "splash"
local EXT     = ".png"
local MAX_N   = 999
 
local BTN_Y   = 7
local IMG_Y   = 48   -- image top (below button row)
 
local exitApp   = false
local rotateOk  = false
local statusTxt = ""
local fileList  = {}
local previewPath = ""   -- copy of splash01.png saved before rotation
 
local phase   = "scan"
local highest = 0
local hasBase = false
local shiftN  = 1
 
local spinChars = { "|", "/", "-", "\\" }
local spinIdx   = 1
 
local statusLbl = nil
local exitLbl   = nil
 
-- Navigation state
local pendingIdx = nil   -- non-nil means build this page next run() call
local browserIdx = 1
 
-- ---- helpers ---------------------------------------------------------------
 
local function imgPath(n)
  if n == 0 then return IMG_DIR .. "/" .. BASE .. EXT end
  return IMG_DIR .. "/" .. BASE .. string.format("%02d", n) .. EXT
end
 
local tmpPath     = IMG_DIR .. "/splash_tmp" .. EXT
local previewTmp  = IMG_DIR .. "/splash_pv"  .. EXT   -- preview copy of splash01
 
local function exists(path) return fstat(path) ~= nil end
 
local function spin()
  spinIdx = (spinIdx % #spinChars) + 1
  return spinChars[spinIdx]
end
 
local function fileSizeStr(path)
  local st = fstat(path)
  if not st then return "?" end
  local sz = st.size or 0
  if sz < 1024 then return sz .. " B"
  elseif sz < 1048576 then return math.floor(sz / 1024) .. " KB"
  else return string.format("%.1f", sz / 1048576) .. " MB" end
end
 
-- ---- file I/O --------------------------------------------------------------
 
local function copyFile(src, dst)
  local inF = io.open(src, "r")
  if not inF then return false, "cannot open " .. src end
  local outF = io.open(dst, "w")
  if not outF then io.close(inF); return false, "cannot create " .. dst end
  while true do
    local data = io.read(inF, 256)
    if data == nil or data == "" then break end
    io.write(outF, data)
  end
  io.close(inF); io.close(outF)
  return true, nil
end
 
local function renameFile(src, dst)
  local ok, err = copyFile(src, dst)
  if not ok then del(dst); return false, err end
  del(src); return true, nil
end
 
-- ---- file list -------------------------------------------------------------
 
local function buildFileList()
  local list = {}
  if exists(imgPath(0)) then
    list[#list + 1] = { label = "splash.png  [ACTIVE]", path = imgPath(0) }
  end
  for n = 1, MAX_N do
    if exists(imgPath(n)) then
      local tag = (n == 1) and "  <- next" or ""
      list[#list + 1] = {
        label = BASE .. string.format("%02d", n) .. EXT .. tag,
        path  = imgPath(n),
      }
    else break end
  end
  return list
end
 
-- ---- page builders ---------------------------------------------------------
 
local showStatusPage, showPreviewPage

showPreviewPage = function()
  local pg = lvgl.page({
    title    = "SplashRotate  v2.3",
    subtitle = "Splash screen on next boot",
    back     = function() showStatusPage() end,
  })
  pg:button({ x=10, y=7, w=100, text="<- Back",
    press = function() showStatusPage() end })
  pg:button({ x=340, y=7, w=100, text="Close",
    press = function() exitApp = true end })
  pg:image({ x=90, y=48, w=300, h=170,
    file = previewTmp, fill = false })
end

showStatusPage = function()
  pendingIdx = nil

  local pg = lvgl.page({
    title    = "SplashRotate  v2.3",
    subtitle = rotateOk and "Rotation complete" or "Error",
    back     = function() exitApp = true end,
  })

  pg:button({ x=10,  y=BTN_Y, w=100, text="Close",
    press = function() exitApp = true end })

  if rotateOk then
    pg:button({ x=120, y=BTN_Y, w=150, text="View Splash ->",
      press = function() showPreviewPage() end })
  end

  local s  = statusTxt
  local nl = string.find(s, "\n")
  local txt
  if nl then txt = string.sub(s,1,nl-1) .. "\n" .. string.sub(s,nl+1)
  else       txt = s end
  txt = txt .. "\n\nFile queue: " .. #fileList .. " file(s) in " .. IMG_DIR
  pg:label({ x=10, y=48, text=txt })
end
 
-- ---- init ------------------------------------------------------------------
 
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
  pg:button({ x=10, y=BTN_Y, w=120, text="Close",
    press=function()
      exitApp = true
      exitLbl:set({ text = "Closing after rotation..." })
    end })
  exitLbl   = pg:label({ x=140, y=BTN_Y+8, text="" })
  statusLbl = pg:label({ x=10,  y=48,      text="Scanning files...  |" })
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
 
  if phase == "idle" then
    if exitApp then del(previewTmp); return 2 end
    return 0
  end
 
  if phase == "scan" then
    hasBase = exists(imgPath(0))
    highest = 0
    for n = 1, MAX_N do
      if exists(imgPath(n)) then highest = n else break end
    end
    if not hasBase and highest == 0 then
      statusTxt = "ABORT: no splash files found in " .. IMG_DIR; phase = "error"
    elseif highest == 0 then
      statusTxt = "Only splash.png present.\nAdd splash01.png etc. to enable cycling."
      phase = "error"
    elseif highest >= MAX_N then
      statusTxt = "ABORT: ceiling reached (splash" .. MAX_N .. ".png exists)."; phase = "error"
    else
      statusLbl:set({ text = "Saving splash01.png  " .. spin() .. "\n" ..
                              highest .. " files to process..." })
      phase = "temp"
    end
 
  elseif phase == "temp" then
    -- Save a copy of splash01.png as the preview file BEFORE renaming anything.
    -- LVGL caches splash.png at boot; displaying previewTmp (a different path)
    -- bypasses that stale cache and shows the correct new active image.
    copyFile(imgPath(1), previewTmp)
    local ok, err = copyFile(imgPath(1), tmpPath)
    if not ok then
      del(tmpPath); del(previewTmp); statusTxt = "ERR saving temp: " .. err; phase = "error"
    else
      del(imgPath(1)); shiftN = 1
      if highest > 1 then
        statusLbl:set({ text = "Shifting files...  " .. spin() .. "\n" ..
                                "Step 1 of " .. (highest-1) .. "  (splash02 -> splash01)" })
        phase = "shift"
      else
        statusLbl:set({ text = "Demoting splash.png  " .. spin() }); phase = "demote"
      end
    end
 
  elseif phase == "shift" then
    local ok, err = renameFile(imgPath(shiftN+1), imgPath(shiftN))
    if not ok then
      del(tmpPath)
      statusTxt = "ERR shifting splash" .. string.format("%02d", shiftN+1) .. ": " .. err
      phase = "error"
    else
      shiftN = shiftN + 1
      if shiftN <= highest-1 then
        statusLbl:set({ text = "Shifting files...  " .. spin() .. "\n" ..
                                "Step " .. shiftN .. " of " .. (highest-1) ..
                                "  (" .. BASE .. string.format("%02d",shiftN+1) .. EXT ..
                                " -> " .. BASE .. string.format("%02d",shiftN) .. EXT .. ")" })
      else
        statusLbl:set({ text = "Demoting splash.png  " .. spin() }); phase = "demote"
      end
    end
 
  elseif phase == "demote" then
    if hasBase then
      local ok, err = renameFile(imgPath(0), imgPath(highest))
      if not ok then
        del(tmpPath); statusTxt = "ERR demoting splash.png: " .. err; phase = "error"
      else
        statusLbl:set({ text = "Promoting new active splash  " .. spin() }); phase = "promote"
      end
    else
      statusLbl:set({ text = "Promoting new active splash  " .. spin() }); phase = "promote"
    end
 
  elseif phase == "promote" then
    local ok, err = renameFile(tmpPath, imgPath(0))
    if not ok then
      statusTxt = "ERR promoting new active: " .. err; phase = "error"
    else
      rotateOk = true
      statusTxt = "Promoted: " .. BASE .. "01" .. EXT .. "  ->  splash.png\n" ..
                  "Demoted:  splash.png  ->  splash" .. string.format("%02d",highest) .. ".png\n" ..
                  (highest-1) .. " file(s) shifted down by 1"
      phase = "done"
    end
 
  elseif phase == "error" then
    rotateOk = false; phase = "done"
 
  elseif phase == "done" then
    fileList = buildFileList()
    if exitApp then return 2 end
    showStatusPage()
    phase = "idle"
  end
 
  return 0
end
 
return { init = init, run = run, useLvgl = true }