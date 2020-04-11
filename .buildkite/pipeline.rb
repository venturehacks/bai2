require 'json'
require 'pathname'

BRANCH = ENV['BUILDKITE_BRANCH'].gsub(/[^\w\-_]/, '').gsub(/-+/, '-').freeze
COMMIT = ENV['BUILDKITE_COMMIT'].freeze
MESSAGE = ENV['BUILDKITE_MESSAGE'].freeze
SKIPCI = MESSAGE && MESSAGE.include?('[skipci]')
STEPS = []

VERSION = JSON.load(`parse-gemspec-cli bai2.gemspec`)['version']

STEPS << {
  label: 'Deploy',
  key: :deploy,
  timeout_in_minutes: 5,
  concurrency: 1,
  concurrency_group: 'bai2/deploy',
  command: <<-EOF
    gem build bai2.gemspec

    grep -q "#{VERSION}" <(fury versions bai2) || EXIT_CODE="$$?" && true
    if [[ "$$EXIT_CODE" == 1 ]]; then
      fury push "bai2-#{VERSION}.gem"
    else
      echo "bai2 version #{VERSION} has previously been released to gemfury, increment the version for a new release"
      exit 1
    fi
  EOF
} if BRANCH == 'master'

puts JSON.dump(steps: STEPS)
