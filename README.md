# sQucumber Redshift

[![Gem Version](https://badge.fury.io/rb/sQucumber-redshift.svg)](https://badge.fury.io/rb/sQucumber-redshift) [![Dependency Status](https://gemnasium.com/badges/github.com/moertel/sQucumber-redshift.svg)](https://gemnasium.com/github.com/moertel/sQucumber-redshift) [![Build Status](https://travis-ci.org/moertel/sQucumber-redshift.svg?branch=master)](https://travis-ci.org/moertel/sQucumber-redshift) [![Test Coverage](https://codeclimate.com/github/moertel/sQucumber-redshift/badges/coverage.svg)](https://codeclimate.com/github/moertel/sQucumber-redshift/coverage) [![Gitter](https://img.shields.io/gitter/room/sQucumber/sQucumber.js.svg?maxAge=2592000?style=flat)](https://gitter.im/moertel/sQucumber)

Bring the BDD approach to writing SQL and be confident that your scripts do what they're supposed to do. Define and execute SQL unit, acceptance and integration tests for AWS Redshift, let them serve as a living documentation for your queries. It's Cucumber - for SQL!

## Example

Suppose you want to test that `kpi_reporting.sql` is producing correct results; its `.feature` file could look as follows:
```cucumber
# features/kpi_reporting.feature

Feature: KPI Reporting

  Scenario: There are some visitors and some orders
    Given the existing table "access_logs":
      | req_date   | req_time | request_id |
      | 2016-07-29 | 23:45:16 | 751fa12d-c51e-4823-8362-f85fde8b7fcd |
      | 2016-07-31 | 22:13:54 | 35c4699e-c035-44cb-957c-3cd992b0ad73 |
      | 2016-07-31 | 11:23:45 | 0000021d-7e77-4748-89f5-cddd0a11d2f9 |
    And the existing table "orders":
      | order_date | product |
      | 2016-07-31 | Premium |
    When the SQL file "kpi_reporting.sql" is executed
    And the resulting table "kpi_reporting" is queried
    Then the result exactly matches:
      | date       | visitors | orders |
      | 2016-07-29 | 1        | 0      |
      | 2016-07-31 | 2        | 1      |
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'squcumber-redshift'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install squcumber-redshift

## Usage

Put your `.feature` files in the directory `feature` in your project's root. (You may use subfolders.)
In order to take advantage of auto-generated Rake tasks, add this to your `Rakefile`:
```
require 'squcumber-redshift/task'
```

The following folder structure
```
└── features
    ├── marketing
    │   ├── sales.feature
    │   └── kpi.feature
    └── development
        └── logs
            └── aggregate.feature
```
Leads to the following Rake tasks
```
$ rake -T
test:sql:marketing[scenario_line_number]
test:sql:marketing:sales[scenario_line_number]
test:sql:marketing:kpi[scenario_line_number]
test:sql:development[scenario_line_number]
test:sql:development:logs[scenario_line_number]
test:sql:development:logs:aggregate[scenario_line_number]
```

### Environment Variables

Make sure the following environment variables are set when running sQucumber's Rake tasks:

| Name | Description |
| ---- | ----------- |
| REDSHIFT_HOST | Hostname of the AWS Redshift cluster |
| REDSHIFT_PORT | Redshift port to connect to |
| REDSHIFT_USER | Name of the Redshift user to use to create a testing database, must be a superuser |
| REDSHIFT_PASSWORD | Password of the Redshift user |
| REDSHIFT_DB | Name of the DB on the Redshift cluster |

Optional environment variables:

| Name | Value | Description | Default |
| ---- | ----- | ----------- | ------- |
| SPEC_SHOW_STDOUT | 1 | Show output of statements executed on the Redshift cluster | 0 |
| KEEP_TEST_DB | 1 | Do not drop the database after test execution (useful for manual inspection) | 0 |
| TEST_DB_NAME_OVERRIDE | _String_ | Define a custom name for the testing database created on the cluster. Setting this to `foo` will result in the database `test_env_foo` being created | random 5-digit integer |


## Contributing

1. Fork it ( https://github.com/moertel/squcumber-redshift/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
