describe("nodezero.global unit tests", function()
  before_each(function()
    package.loaded["global"] = nil

    -- Require fresh module instance
    require("global")
  end)
  after_each(function()
    package.loaded["utils.global"] = nil
  end)
  it("should have profiles", function()
    assert.truthy(NodeZeroVim.profiles)
  end)
  it("should have utils", function()
    assert.truthy(NodeZeroVim.utils)
  end)
end)
