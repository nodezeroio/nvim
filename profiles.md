# Profiles

Profiles are the core component of `nodezero.nvim`.

A profile is a set of configuration, [plugins](./plugins.md), and any other setup that may be necessary for a particular profile.


## Profile Definition

A profile is defined by a `profile definition`, which determines:

1. Where to find the profile
2. In what order to laod the profile

## Profile Storage

All plugins are cloned to `$XDG_DATA_HOME/nodezero.nvim/profiles` by default. This can be overridden using the `NODEZERO_NVIM_PROFILES_PATH`.

Profiles will be downloaded from `https://github.com` by default, this can be overridden by setting: `NODEZERO_NVIM_PROFILE_REPOSITORY`

Only one profile with the same name/path may be specified, if multiples are defined this will result in an error.


### Creating profiles

A profile is a directory where plugins and configuration are defined. For example a profile may look like this: 

```txt
.
├── config
│   ├── autocmds.lua
│   ├── init.lua
│   ├── keymaps.lua
│   └── options.lua
└── plugins.lua
```

Where `plugins.lua` specifies all the plugins for a profile, this could be a file named `plugins.lua` or a directory with an `init.lua` file like `plugins/init.lua`. Plugins should return tables that specify the [plugin definition](./plugins.md)

Similarly config may be defined as a file named `config.lua` or a directory like in the example above. 


### Example Profile Config

```lua
{
    "nodezero/core", -- the plugin path on the repository, for example nodezero/core would correspond to ${NVIM_PROFILE_REPOSITORY}/nodezero/core
    spec {
        name="core", -- optional parameter, if name is specified the profile will be cloned at, if not specified it will be cloned at a normalized path based on the repository path. For example if spec.name is not specified it will be cloned and the plugin path is 'nodezero/core' it will be cloned at `nodezero-core``
        vcs="local|git", -- if set to file, this will look for the profile on the local file system at $HOME/.local/share/nodezero.nvim/profiles, defaults to `git` 
        priority=0, -- optional parameter that will determine the order in which profiles are loaded, and subsequently how merges of common plugins will be handled. The lowest priority is 0. The higher priority profile will always override any conflicts will lower priority profiles. If no priority is set profiles will be loaded according to lexigraphical order 
    }
}
```

### Profile Loading

The profiles are loaded based on the following logic: 

1. Retrieve all profile config from 'nodezero.profiles.config'
2. Sort profiles based on sorting logic
3. Clone the profile repository, if not already done, based on configured profile path and profile repository
4. Load all profile configuration in priority order
5. Load all profile plugin configuration based on priority order of the profiles
6. Clone plugins and call appropriate setup logic


