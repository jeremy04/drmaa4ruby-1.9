require 'helper'
require "drmaa"
require 'pp'

class Job < DRMAA::JobTemplate
  def initialize
    super
    self.join = true
  end
  def set_meta(command,args)
    self.command = command
    self.arg = args
  end
  def set_hold(value)
    self.hold = value
  end
  def holding?
   begin
    self.hold?
   rescue DRMAA::DRMAAInvalidAttributeValueError
    false
   end
  end
end

class ParJob 
  attr_accessor :jobs, :dep_hash, :sge_ids
  def initialize(jobs)
   @jobs = jobs
  end
 
  def holdit
    @jobs.each_index { |i| 
    
    @jobs[i].set_hold false
    puts "NOT ON HOLD"
   }
  end
   
  def number_jobs
    @jobs.length
  end

  def make_dep(ids)
    @dep_hash = {}
  end
end

class SerialJob < ParJob
  def initialize(jobs)
    super
  end
  def holdit

     @jobs.first.set_hold false
       puts "First job not on hold"
     x=1
     @jobs[1..jobs.length].each { |i|
        @jobs[x].set_hold true
        x+=1
        puts "next job ON HOLD"
     }
  end
  def make_dep(ids)
    h = {}
    ids.each_index do |x|
      a=ids[x..x+1]
      h[a.first] = a.last unless x.eql?(ids.length) or a.first.eql?(a.last)
    end
    @dep_hash = h
  end

end

class Manager
  attr :stack, :session,:current_job,:num_tasks,:jobs_complete
  def initialize(job_obj_arry,session)
     @stack = job_obj_arry
     @session = session
     @num_tasks = @stack.length
  end
  def run
    if @stack.empty? then 
        puts "All tasks started" 
        return
    end
    job_run = @stack.shift
    job_run.holdit
    job_list = []
    pp "^^ HERES THE STACK"
    job_run.jobs.each_with_index { |t,k|
      id = session.run(t)
      pp "Started #{id}.."
      pp "****"
      job_list << id
     }
     job_run.make_dep(job_list)
     job_run.sge_ids = job_list
     @current_job = job_run
     @jobs_complete = 0
  end
  def check?
     @current_job.sge_ids.each { |j|

     begin
        info = @session.wait(j,1)                                  
        if info.nil? then
           pp "info is nil.."
           next
        end
        job = info.job
     rescue DRMAA::DRMAAInvalidJobError
           pp "DRMAA INVALID JOB ID ERROR"
           next
     end
     if @current_job.dep_hash.has_key?(job)
        @session.release(@current_job.dep_hash[job])
     end
     if info.wifexited?
        puts job + " returned with " + info.wexitstatus.to_s
        @jobs_complete+=1
     elsif info.wifaborted?                   
        puts job + " aborted"
        @jobs_complete+=1
     elsif info.wifsignaled?
        @jobs_complete+=1
        puts job + " died from " + info.wtermsig
     end
     }
     if @jobs_complete >= @current_job.sge_ids.length then
	return true
     else
        return false
     end

  end

end
    
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
		skip
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


	def test_serial
		skip
		j = Job.new
		j.set_meta("sleep",["10"])
		j2 = Job.new
		j2.set_meta("sleep",["20"])

		# create serial job
		s = SerialJob.new([j])
		p = ParJob.new([j,j2])

		m = Manager.new([s],@session)
		# Start the first job!!
		m.run

		@tasks_finished = 0	
         	while 1
		  if @tasks_finished >= m.num_tasks then
		    break
		  end
	   	  if m.check? then
                    puts "job #{@tasks_finished} done"
                    m.run
		    @tasks_finished+=1
		  end
		end
                
		assert_not_nil(m.current_job.number_jobs)
	end
end
