local M = {}
local gitUtils = require("nodezero.utils.git")

M.loaded = {}
function M.getProfiles(overrides) end

function M.setup()
-- 1. retrieve the profiles from 'profile-config'
-- 2. retrieve the profile repository base 'nodezero.profiles.utils.getBaseRepositoryURL'
-- 3. retrieve the profiles path using 'nodezero.profiles.utils.getProfilesPath'
-- 4. normalize the profile definitioins using 'nodezero.profiles.utils.normalizeProfileDefinitions'
-- 5. normalize the plugin dependencies using 'nodezero.profiles.utils.normalizePluginDependencies'
-- 6. load any overrides from 'nodezero.overrides'
-- 7. check if the profiles are already existing using the 'nodezero.utils.fs.ensurePath' using the profile path with the 'profile.spec.name'
-- 8. if the path does not exist then it should be cloned using 'nodezero.utils.git.cloneRepo' using the profile path and the repository on the repoDetails
-- 9. after ensuring the profiles are cloned, require the profile config if it exists
-- 10. after requiring the config if it exists, require the plugins, if they exist, and add them to 'profile.plugins'
-- 11. set the M.loaded value to the result of 'nodezero.profiles.utils.mergePlugins'
end
return M
