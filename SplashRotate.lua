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
--  Version: 1.0.0
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
-- A PARTICULAR PURPOSE. See the GNU General Public License for more details
--
-- =============================================================================
-- SplashRotate.lua
-- Each run does exactly two file operations:
--   1. Archive current splash.png -> splash(highest+1).png
--   2. Promote splash(lowest).png -> splash.png
--
-- Total file count stays constant. Numbers grow but never wrap,
-- supporting splash01..splash99 then splash100..splash999 naturally
-- (string.format("%02d", 100) = "100" - minimum width, not fixed width).
--
-- Place in /SCRIPTS/TOOLS/  Run from EdgeTX Tools menu.
-- EdgeTX 2.11.5 / EdgeTX Lua Reference 2.11

local IMG_DIR = "/images"
local BASE    = "splash"
local EXT     = ".png"
local MAX_N   = 999      -- supports up to splash999.png

local exitApp = false

local function imgPath(n)
  if n == 0 then
    return IMG_DIR .. "/" .. BASE .. EXT
  end
  return IMG_DIR .. "/" .. BASE .. string.format("%02d", n) .. EXT
end

local function exists(path)
  return fstat(path) ~= nil
end

-- Copy using functional io (confirmed working in EdgeTX 2.11.5).
-- io.read(f, n) returns n bytes or nil/"" at EOF.
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
  io.close(inF)
  io.close(outF)
  return true, nil
end

local function renameFile(src, dst)
  local ok, err = copyFile(src, dst)
  if not ok then return false, err end
  del(src)
  return true, nil
end

-- ---- rotation logic --------------------------------------------------------

local function doRotate()
  local hasBase = exists(imgPath(0))

  -- find lowest numbered splashNN.png: scan forward, stop at first found.
  -- this is efficient even when numbers are large (e.g. splash104 onwards).
  local lowest = 0
  for n = 1, MAX_N do
    if exists(imgPath(n)) then
      lowest = n
      break
    end
  end

  local highest = lowest
  if lowest > 0 then
    for n = lowest + 1, MAX_N do
      if exists(imgPath(n)) then
        highest = n
      else
        break
      end
    end
  end

  -- nothing at all to work with
  if not hasBase and lowest == 0 then
    return "ABORT: no splash files found in " .. IMG_DIR
  end

  -- ceiling check
  if highest >= MAX_N then
    return "ABORT: splash" .. MAX_N .. ".png exists - archive cleanup needed."
  end

  -- step 1: archive splash.png -> splash(highest+1).png
  if hasBase then
    local archivePath = imgPath(highest + 1)
    local ok, err = renameFile(imgPath(0), archivePath)
    if not ok then
      return "ERR archiving splash.png: " .. tostring(err)
    end
    highest = highest + 1
  end

  -- if there are no numbered files (only had splash.png), we are done
  if lowest == 0 then
    return "Archived splash.png as splash" .. string.format("%02d", highest) ..
           ".png. Add more splashNN.png files to enable cycling."
  end

  -- step 2: promote splash(lowest).png -> splash.png
  local promotedName = "splash" .. string.format("%02d", lowest) .. ".png"
  local ok, err = renameFile(imgPath(lowest), imgPath(0))
  if not ok then
    return "ERR promoting " .. promotedName .. ": " .. tostring(err)
  end

  -- archive count = files remaining as splashNN (lowest has been promoted)
  local archiveCount = highest - lowest
  return "Active: " .. promotedName .. "  Archive: " .. archiveCount .. " file(s)"
end

-- ---- renumbering logic -----------------------------------------------------------
-- the 'doCleanup()' function collects all the 'splashNN.png' files and renumbers
-- them from 'splash01.png' - t also stores the status label references so the cleanup
-- button can update it in place - the 'Archive Cleanup' button will be alongside 'Close'
-- ------------------------------------------------------------------------------------
 
local function doCleanup()
  local files = {}
  for n = 1, MAX_N do
    if exists(imgPath(n)) then
      files[#files + 1] = n
    end
  end
  if #files == 0 then
    return "No numbered splash files to renumber."
  end
  for i, oldN in ipairs(files) do
    local newN = i
    if oldN ~= newN then
      local ok, err = renameFile(imgPath(oldN), imgPath(newN))
      if not ok then
        return "ERR renaming splash" .. string.format("%02d", oldN) ..
               ": " .. tostring(err)
      end
    end
  end
  return "Renumbered " .. #files .. " file(s): splash01.." ..
         string.format("%02d", #files) .. ".png"
end

-- ---- init ------------------------------------------------------------------
-- Work happens here: two file copies at most, so Loading... is brief.
-- Then the LVGL result page is built and displayed.

local function init()
  if lvgl == nil then return end

  local ok, result = pcall(doRotate)
  local status = ok and result or ("LUA ERR: " .. tostring(result))

  local pg = lvgl.page({
    title    = "Splash Rotator",
    subtitle = status,
    back     = function() exitApp = true end,
  })

  -- pg:label({
    -- x    = 10,
    -- y    = 10,
    -- text = status,
  -- })

  -- pg:button({
    -- x     = 10,
    -- y     = 50,
    -- w     = 120,
    -- text  = "Close",
    -- press = function() exitApp = true end,
  -- })

  local lbl = pg:label({
    x    = 10,
    y    = 10,
    text = status,
  })

  pg:button({
    x     = 10,
    y     = 50,
    w     = 150,
    text  = "Archive Cleanup",
    press = function()
      local ok2, res2 = pcall(doCleanup)
      local msg = ok2 and res2 or ("LUA ERR: " .. tostring(res2))
      lbl:set({ text = msg })
    end,
  })

  pg:button({
    x     = 170,
    y     = 50,
    w     = 120,
    text  = "Close",
    press = function() exitApp = true end,
  })

end

-- ---- run -------------------------------------------------------------------

local function run(event, touchState)
  if lvgl == nil then
    lcd.clear()
    lcd.drawText(10, 20, "Splash Rotator",         MIDSIZE)
    lcd.drawText(10, 50, "Requires EdgeTX v2.11+", 0)
    if event == EVT_VIRTUAL_EXIT then return 2 end
    return 0
  end
  if exitApp then return 2 end
  return 0
end

return { init = init, run = run, useLvgl = true }
