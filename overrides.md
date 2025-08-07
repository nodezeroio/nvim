# Overrides

Nodezero nvim has the ability to override the repository where a particular plugin or profile will be loaded from. 

For example we could setup a profile configuration at 'lua/nodezero/profiles/config.lua'
```lua
return {
    {
        "nodezeroio/nvim-profiles-core"
    }
}
```

By default this will be cloned like this: `git clone https://github.com/nodezeroio/nvim-profiles-core.git`. 

If this was, for example forked, into another repository at 'https://github.com/some-secondary-repo/nvim-profiles-core.git' rather than having to explicitly set this in the `profiles.config` like this:


```lua
return {
    {
        "some-secondary-repo/nvim-profiles-core"
    }
}
```

We can instead add an override to the [overrides file](./lua/overrides.lua) like this:

```lua

return {
  ["nodezeroio/nvim-profiles-core"] = "some-secondary-repo/nvim-profiles-core",
}

```

Which will enable us to have common configuration, but be able to override where profiles are coming from either for the purposes of customization or security.

