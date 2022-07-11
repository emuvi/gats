require_relative "main"
require "test/unit/assertions"
include Test::Unit::Assertions

assert_equal(is_image("asdf.jpg", "123sdf"), true)
assert_equal(is_image("asdf.png", "123sdf"), true)
assert_equal(is_image("asdf.jpg", "a23sdf"), false)
assert_equal(is_image("asdf.jpj", "123sdf"), false)
assert_equal(is_image("sddfgasd", "3x.png"), true)
assert_equal(is_image("dlfghdfg", "2xswdf"), false)
assert_equal(is_image("asdf.jpg", "2x.jpg"), true)
assert_equal(is_image("asdf.png", "a23sds"), false)
