--
-- Fin CSV Importer
--
-- Unofficial extension to import CSV data exported from Fin - Budget Tracker 
-- https://apps.apple.com/us/app/fin-budget-tracker/id1489698531
-- 
--

Importer{version=1.00, format="Fin-Export", fileExtension="csv"}

local function strToDate (str)
  -- Helper function for converting localized date strings to timestamps.
  local y, m, d = string.match(str, "(%d%d%d%d).(%d%d).(%d%d).")
  return os.time{year=y, month=m, day=d}
end

function ReadTransactions (account)
  local transactions = {}
  local count = 0
  for line in assert(io.lines()) do
    local values = {}
    local comment = ""

    count = count + 1
    
    if count > 1 then -- skip first line with column headers
      values = ParseCSVLine(line, ",")

      if #values >= 9 then

        if values[5] ~= values[6] then
          error(string.format("Could not import line %i: Source Currency needs to match Target Currency (\"%s\" != \"%s\")",
            count, values[5], values[6]))
        end

        if values[8] ~= "-" then
          comment = string.format("Location: %s / %s", values[8], values[9])
        end

        local transaction = {
          bookingDate = strToDate(values[1]),
          purpose = values[2],
          category = values[3],
          amount = tonumber(values[4]),
          currency = values[5],
          comment = comment
        }
        table.insert(transactions, transaction)
      end

    end
  end
  return transactions
end

-- from http://lua-users.org/wiki/LuaCsv
function ParseCSVLine (line,sep) 
  local res = {}
  local pos = 1
  sep = sep or ','
  while true do 
    local c = string.sub(line,pos,pos)
    if (c == "") then break end
    if (c == '"') then
      -- quoted value (ignore separator within)
      local txt = ""
      repeat
        local startp,endp = string.find(line,'^%b""',pos)
        txt = txt..string.sub(line,startp+1,endp-1)
        pos = endp + 1
        c = string.sub(line,pos,pos) 
        if (c == '"') then txt = txt..'"' end 
        -- check first char AFTER quoted string, if it is another
        -- quoted string without separator, then append it
        -- this is the way to "escape" the quote char in a quote. example:
        --   value1,"blub""blip""boing",value3  will result in blub"blip"boing  for the middle
      until (c ~= '"')
      table.insert(res,txt)
      assert(c == sep or c == "")
      pos = pos + 1
    else  
      -- no quotes used, just look for the first separator
      local startp,endp = string.find(line,sep,pos)
      if (startp) then 
        table.insert(res,string.sub(line,pos,startp-1))
        pos = endp + 1
      else
        -- no separator found -> use rest of string and terminate
        table.insert(res,string.sub(line,pos))
        break
      end 
    end
  end
  return res
end
