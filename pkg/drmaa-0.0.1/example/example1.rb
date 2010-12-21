require 'drmaa'
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

session ||= DRMAA::Session.new
t = Sleeper.new
jobid = session.run(t)
puts "job: " + jobid

info = nil
while info.nil?

begin
	info = session.wait(jobid, 1)
	puts "Waiting for job to end..."

rescue DRMAA::DRMAAInvalidJobError
	puts "We sometimes recieve an error.. Working on what this means."
	info = true

end
end
