require 'helper'
require "drmaa"
require 'pp'
 
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
                puts "\nSession Started"
		@session = DRMAA::Session.new
	end

	def teardown
                puts "\nSession Ended"
		@session.finalize(0)
	end

	def test_session
		assert_not_nil(@session)
	end

	def test_session_exception
                skip
		assert_raise DRMAA::DRMAAAlreadyActiveSessionError do
			raise @session = DRMAA::Session.new
		end
	end

	def test_version
		@version = DRMAA.version
		assert_not_nil(@version)
	end

	def test_contact
                t = DRMAA::JobTemplate.new
                t.command = "/bin/sleep"
                t.arg = ["2"]
                t.stdout = ":/dev/null"
                t.join = true
                jobid = @session.run(t)
		@contact = DRMAA.contact
                @session.finalize(0)
                @session = DRMAA::Session.new(@contact)
                info = @session.wait(jobid) 
		assert_not_nil(info)
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

        def test_get
                t = DRMAA::JobTemplate.new
                command = "/bin/sleep"
                t.command = command
                t.arg = ["1"]
                t.stdout = ":/dev/null"
                t.join = true
                jobid = @session.run(t)
                attr = t.get("drmaa_remote_command")
                assert_equal(attr,command)
        end


	def test_vget
                t = DRMAA::JobTemplate.new
                command = "/bin/sleep"
                t.command = command
                t.arg = ["1","LOL"]
                t.stdout = ":/dev/null"
                t.join = true
                jobid = @session.run(t)
                attr = t.vget("drmaa_v_argv")
                assert_equal(attr,t.arg)
        end



	def test_run_bulk
                skip
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

	def test_sync
		skip
		t = DRMAA::JobTemplate.new
		t.command = "/bin/sleep"
		t.arg = ["10"]
                t.stdout = ":/dev/null"
                t.join = true

		array = []
                jobid = @session.run(t)
		array << jobid
		jobid = @session.run(t)
		array << jobid

		@session.sync!(array)
		puts "Jobs are Done!"

#		array.each { |job|
#			puts "Collecting job #{job}"
#			retval = @session.wait(job)
#			if retval.wifexited? then puts "Job has finished.." end
#		}
	end


end
