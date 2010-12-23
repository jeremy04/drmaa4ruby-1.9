require 'helper'
require "drmaa"

class Sleeper < DRMAA::JobTemplate
       def initialize
                super
                self.command = "/bin/sleep"
                self.arg     = ["1"]
                self.stdout  = ":/dev/null"
                self.join    = true
       end
end

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

	def test_run
		t = DRMAA::JobTemplate.new
		t.command = "/bin/sleep"
		t.arg = ["1"]
		t.stdout = ":/dev/null"
		t.join = true
		jobid = @session.run(t)
		assert_not_nil(jobid)
	end

	def test_run_bulk
		ntasks = 30	
		t = Sleeper.new
		pre = @session.run_bulk(t, 1, ntasks, 1)
		t.hold = true
		suc = @session.run_bulk(t, 1, ntasks, 1)
		# TODO -- not finished writing this test
	end
	
	def test_set_v
		t = Sleeper.new
		assert_not_nil(t)
	end
end
