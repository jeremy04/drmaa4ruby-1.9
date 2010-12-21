require 'helper'
require "drmaa"

class TestDRMAA < Test::Unit::TestCase

	def setup
		@session = DRMAA::Session.new
	end

	def teardown
		@session.finalize(0)
	end

	def test_session
		assert_not_nil(@session)
	end

	def test_session_exception
		assert_raise DRMAA::DRMAAAlreadyActiveSessionError do
			raise @session = DRMAA::Session.new
		end
	end

	def test_version
		@version = DRMAA.version
		assert_not_nil(@version)
	end

	def test_contact
		@contact = DRMAA.contact
		assert_not_nil(@contact)
	end

	def test_implementation
		@impl = DRMAA.drmaa_implementation
		assert_not_nil(@impl)
	end

	def test_drm
		@drm = DRMAA.drm_system
		assert_not_nil(@drm)
	end

end
