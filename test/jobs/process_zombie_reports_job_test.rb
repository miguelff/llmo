require "test_helper"

class ProcessZombieReportsJobTest < ActiveJob::TestCase
  test "A report that is zombie is retried" do
    report = Report.create!(query: "test", status: :processing, owner: users(:jane))

    assert_not Report.zombies.exists?, "Report should not be zombie"

    travel (Report::ZOMBIE_REPORT_THRESHOLD + 1.second) do
      assert_equal 1, Report.zombies.count, "Report should be zombie"
      assert_difference "Report.zombies.count", -1 do
        ProcessZombieReportsJob.perform_now
      end
    end
  end
end
