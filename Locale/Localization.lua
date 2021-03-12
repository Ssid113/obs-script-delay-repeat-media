local localization = { locales = {} }

local currentLocale = 'en' -- the default language

local choise_locales = {[1] = 'en', [2] = 'ru'}

function localization.setLocale(newLocale)
  currentLocale = choise_locales[newLocale]
  assert(localization.locales[currentLocale], ("The locale %q was unknown"):format(newLocale))
end

local function translate(id)
  local result = localization.locales[currentLocale][id]
  assert(result, ("The id %q was not found in the current locale (%q)"):format(id, currentLocale))
  return result
end

localization.translate = translate

setmetatable(localization, {__call = function(_,...) return translate(id) end})

return localization