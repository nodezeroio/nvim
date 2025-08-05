describe("nodezero.global unit tests", function()
  before_each(function()
    package.loaded["nodezero"] = nil

    -- Require fresh module instance
    require("nodezero")
  end)
  after_each(function()
    package.loaded["nodezero"] = nil
  end)
  it("should have profiles", function()
    assert.truthy(NodeZeroVim.profiles)
  end)
  it("should have utils", function()
    assert.truthy(NodeZeroVim.utils)
  end)
end)
