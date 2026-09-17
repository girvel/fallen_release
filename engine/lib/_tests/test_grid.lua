local vector = require("engine.lib.vector")

describe("Grid library", function()
  _G.unpack = table.unpack

  local grid = require("engine.lib.grid")
  local v = require("engine.lib.vector").new


  describe("grid.from_matrix()", function()
    it("should build a grid from matrix", function()
      local base_matrix = {
        {1, 2, 3},
        {4, 5, 6},
        {7, 8, 9},
      }
      assert.are_same(
        {1, 2, 3, 4, 5, 6, 7, 8, 9},
        grid.from_matrix(base_matrix, v(3, 3))._inner_array
      )
    end)
  end)

  describe("find_free_position", function()
    it("finds the closest nil", function()
      local this_grid = grid.from_matrix({
        {nil, nil, 111},
        {111, 111, 111},
        {111, 111, 111},
      }, v(3, 3))

      assert.are_equal(v(2, 1), this_grid:find_free_position(v(2, 2)))
    end)

    it("does not clash with grid borders", function()
      local this_grid = grid.from_matrix({
        {nil, nil, 111},
        {111, 111, 111},
        {111, 111, 111},
      }, v(3, 3))

      assert.are_equal(v(2, 1), this_grid:find_free_position(v(3, 3)))
    end)

    it("can accept max radius value", function()
      local this_grid = grid.from_matrix({
        {nil, nil, 111},
        {111, 111, 111},
        {111, 111, 111},
      }, v(3, 3))

      assert.are_equal(nil, this_grid:find_free_position(v(3, 3), 2))
    end)
  end)

  describe("grid.rhombus", function()
    it("works", function()
      local m = grid.from_matrix({
        {0, 0, 0, 0},
        {0, 0, 0, 0},
        {0, 0, 0, 0},
        {0, 0, 0, 0},
      }, v(4, 4))

      local expected_order = {
        v(3, 3),
        v(3, 4),
        v(4, 3),
        v(3, 2),
        v(2, 3),
        v(4, 4),
        v(4, 2),
        v(3, 1),
        v(2, 2),
        v(1, 3),
        v(2, 4),
        v(4, 1),
        v(2, 1),
        v(1, 2),
        v(1, 4),
        v(1, 1),
      }

      local counter = 0
      for x, y in m:rhombus(v(3, 3), 4) do
        counter = counter + 1
        assert.are_equal(expected_order[counter], v(x, y))
      end

      assert.are_equal(#expected_order, counter)
    end)

    it("yields correct x, y, value, and r outputs", function()
      local m = grid.from_matrix({
        {10, 20, 30},
        {40, 50, 60},
        {70, 80, 90},
      }, v(3, 3))

      local expected = {
        { pos = v(2, 2), val = 50, r = 0 },
        { pos = v(2, 3), val = 80, r = 1 },
        { pos = v(3, 2), val = 60, r = 1 },
        { pos = v(2, 1), val = 20, r = 1 },
        { pos = v(1, 2), val = 40, r = 1 },
      }

      local counter = 0
      for x, y, val, r in m:rhombus(v(2, 2), 1) do
        counter = counter + 1
        local exp = expected[counter]
        assert.is_not_nil(exp, "Yielded more values than expected!")
        assert.are_equal(exp.pos, v(x, y))
        assert.are_equal(exp.val, val)
        assert.are_equal(exp.r, r)
      end
      assert.are_equal(#expected, counter)
    end)

    it("automatically calculates required radius to cover grid if omitted", function()
      local m = grid.from_matrix({
        {1, 2},
        {3, 4},
      }, v(2, 2))

      local expected_order = {
        v(2, 2),
        v(2, 1),
        v(1, 2),
        v(1, 1),
      }

      local counter = 0
      for x, y in m:rhombus(v(2, 2)) do
        counter = counter + 1
        assert.are_equal(expected_order[counter], v(x, y))
      end
      assert.are_equal(#expected_order, counter)
    end)

    it("safely clamps excessively large max_radius without extra iterations", function()
      local m = grid.new(v(2, 2))
      local counter = 0

      for _ in m:rhombus(v(1, 1), 10000) do
        counter = counter + 1
      end

      assert.are_equal(4, counter)
    end)

    it("starts from completely outside the grid bounds and accurately slices visible rings", function()
      local m = grid.new(v(3, 3))

      local expected_order = {
        v(1, 2),
        v(1, 3), v(2, 2), v(1, 1),
        v(2, 3), v(3, 2), v(2, 1),
        v(3, 3), v(3, 1),
      }

      local counter = 0
      for x, y in m:rhombus(v(0, 2)) do
        counter = counter + 1
        assert.are_equal(expected_order[counter], v(x, y))
      end
      assert.are_equal(#expected_order, counter)
    end)

    it("yields absolutely nothing instantly if the start and radius miss the grid completely", function()
      local m = grid.new(v(5, 5))
      local counter = 0

      for _ in m:rhombus(v(20, 20), 5) do
        counter = counter + 1
      end

      assert.are_equal(0, counter)
    end)

    it("handles a max_radius of 0 perfectly", function()
      local m = grid.new(v(3, 3))
      local counter = 0
      local yielded_pos

      for x, y, _, r in m:rhombus(v(2, 2), 0) do
        counter = counter + 1
        yielded_pos = v(x, y)
        assert.are_equal(0, r)
      end

      assert.are_equal(1, counter)
      assert.are_equal(v(2, 2), yielded_pos)
    end)

    it("skips center point if center is outside but radius intersects grid", function()
      local m = grid.new(v(3, 3))

      local counter = 0
      local yielded_pos
      local yielded_r

      for x, y, _, r in m:rhombus(v(-10, -10), 22) do
        counter = counter + 1
        yielded_pos = v(x, y)
        yielded_r = r
      end

      assert.are_equal(1, counter)
      assert.are_equal(v(1, 1), yielded_pos)
      assert.are_equal(22, yielded_r)
    end)

    it("works seamlessly on 1D asymmetric grids", function()
      local m = grid.new(v(5, 1)) -- A 5x1 horizontal line
      
      local expected_order = {
        v(3, 1),
        v(4, 1),
        v(2, 1),
        v(5, 1),
        v(1, 1),
      }

      local counter = 0
      for x, y in m:rhombus(v(3, 1)) do
        counter = counter + 1
        assert.are_equal(expected_order[counter], v(x, y))
      end
      
      assert.are_equal(5, counter)
    end)
  end)
end)
