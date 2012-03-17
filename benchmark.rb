require "queue_classic"
require "benchmark"

N = 5
M = 10_000

puts("num_jobs=#{QC.count}")
puts("inserting #{M} jobs into default queue")
M.times do |i|
  QC.enqueue("1.even?")
end
puts("done")
puts("num_jobs=#{QC.count}")

def new_worker
  QC::Worker.new(
    QC::QUEUE,
    QC::TOP_BOUND,
    QC::FORK_WORKER,
    QC::LISTENING_WORKER,
    QC::MAX_LOCK_ATTEMPTS
  )
end

workers = {}
N.times {|i| workers[i] = new_worker}

print("\n")
Benchmark.bm do |test|
  test.report("#{N} workers") do
    N.times.map do |i|
      Thread.new {(M/N).times {workers[i].work}}
    end.map {|t| t.join}
  end
end
print("\n")

puts("num_jobs=#{QC.count}")
