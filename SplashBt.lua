-- =============================================================================
--
--  ____  _                __        __                
-- |  _ \| |_ __ _ ___ ____\ \      / /__ _ _ __ ___  
-- | |_) | __/ _` / __|_  / \ \ /\ / / _` | '__/ _ \ 
-- |  __/| || (_| \__ \/ /   \ V  V / (_| | | |  __/ 
-- |_|    \__\__,_|___/___|   \_/\_/ \__,_|_|  \___|
--
--
--  PtaszWare
--  by: Mark Ptaszynski
--  Copyright: March, 2026
--  Version: 1.1.0
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
-- SplashBt.lua
-- Silent splash rotator - runs once on every radio boot via Global Functions
-- Radio Settings -> Special Functions -> On -> Lua script -> SplashBt
--
-- Rotates /images/splash.png through the archive on every power-on:
--   1. Archives current splash.png -> splash(highest+1).png
--   2. Promotes splash(lowest).png -> splash.png
--
-- Rotation count is saved to /images/splashbt.cnt after each successful rotate.
-- Open that file in any text editor to verify the tally.
--
-- Place in /SCRIPTS/FUNCTIONS/SplashBt.lua
-- EdgeTX 2.11.5 / Lua Reference 2.11
--
-- Function scripts are called repeatedly by EdgeTX. The 'done' flag
-- ensures the rotation runs exactly once per boot session

local IMG_DIR      = "/images"
-- local IMG_DIR      = "/SCRIPTS/FUNCTIONS"
local BASE         = "splash"
local EXT          = ".png"
local MAX_N        = 999
local COUNTER_FILE = "/SCRIPTS/FUNCTIONS/splashbt.cnt"

local done = false   -- guard: rotate once per boot, not every frame
local startTime = nil        -- ADD: timestamp of first run() call
local DELAY     = 300        -- ADD: 300 x 10ms = 3 seconds
							 -- set DELAY to 400 = 4 seconds
							 -- set DELAY to 500 = 5 seconds
							 -- set DELAY to 600 = 6 seconds, etc, etc

local function imgPath(n)
  if n == 0 then
    return IMG_DIR .. "/" .. BASE .. EXT
  end
  return IMG_DIR .. "/" .. BASE .. string.format("%02d", n) .. EXT
end

local function exists(path)
  return fstat(path) ~= nil
end

local function copyFile(src, dst)
  local inF = io.open(src, "r")
  if not inF then return false end
  local outF = io.open(dst, "w")
  if not outF then io.close(inF); return false end
  while true do
    local data = io.read(inF, 256)
    if data == nil or data == "" then break end
    io.write(outF, data)
  end
  io.close(inF)
  io.close(outF)
  return true
end

local function renameFile(src, dst)
  if not copyFile(src, dst) then
	del(dst)		-- this line added to delette a corrupted partial file 
	                -- when script fails due to dst file being copied and
					-- display at the same time - happens on random boots
					-- not every time
	return false
  end
  del(src)
  return true
end

-- ---- counter helpers -------------------------------------------------------

local function readCounter()
  local f = io.open(COUNTER_FILE, "r")
  if not f then return 0 end
  local raw = io.read(f, 16)   -- counter fits easily in 16 bytes
  io.close(f)
  return tonumber(raw) or 0
end

local function writeCounter(n)
  local f = io.open(COUNTER_FILE, "w")
  if not f then return end
  io.write(f, tostring(n))
  io.close(f)
end

-- ---- rotation logic --------------------------------------------------------

local function doRotate()
  local hasBase = exists(imgPath(0))

  -- find lowest numbered splashNN.png
  local lowest = 0
  for n = 1, MAX_N do
    if exists(imgPath(n)) then
      lowest = n
      break
    end
  end

  -- find highest (contiguous scan from lowest)
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

  -- nothing to do
  if not hasBase and lowest == 0 then return end
  if highest >= MAX_N then return end

  -- step 1: archive splash.png -> splash(highest+1).png
  if hasBase then
    renameFile(imgPath(0), imgPath(highest + 1))
    highest = highest + 1
  end

  -- step 2: promote lowest -> splash.png
  if lowest > 0 then
    renameFile(imgPath(lowest), imgPath(0))
  end
  
  return true

  -- step 3: increment and save the rotation counter
  -- writeCounter(readCounter() + 1)
end

-- ---- function script entry point -------------------------------------------
-- EdgeTX calls run() on every frame while the Special Function is active
-- We rotate once (guarded by 'done') then do nothing further

-- local function run(event)
--   if not done then
--    done = true
--    local ok, rotated = pcall(doRotate)
--    if ok and rotated then
--      writeCounter(readCounter() + 1)
--    end
--  end
-- end

-- local function run(event)
--  if not done then
--    done = true
--    local ok, rotated = pcall(doRotate)
--  writeCounter(readCounter() + 1)   -- ADD: heartbeat - increments every boot regardless	
--  end
--end

local function run(event)
  if not done then
    if startTime == nil then
      startTime = getTime()   -- record first call
    end
    if (getTime() - startTime) < DELAY then
      return                  -- sit idle until delay has passed
    end
    done = true
    local ok, rotated = pcall(doRotate)
    writeCounter(readCounter() + 1)
  end
end

return { run = run }
