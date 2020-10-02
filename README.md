# SierraCheckInCardService

[![Build Status](https://travis-ci.com/NYPL/SierraCheckInCardService.svg?branch=main)](https://travis-ci.com/NYPL/SierraCheckInCardService) [![GitHub version](https://badge.fury.io/gh/nypl%2FsierraCheckInCardService.svg)](https://badge.fury.io/gh/nypl%2FsierraCheckInCardService)

Function that returns the matching check-in card (and associated boxes) for a given holdings record identifier. This provides information on the most recent issues/copies received for a serial, which may or may not be represented in the holding record. This retrieves the data from the database created by [SierraCheckInCardPoller](https://github.com/NYPL/SierraCheckInCardPoller)

## Data Structure

This function accepts the data structure from the `SierraCheckInCardPoller` and simplifies it somewhat for easier consumption by applications. This does not remove any fidelity from the data, merely combines related fields so that their purpose is clearer.

### Fields

- box_id: Identifier for the check-in box
- holding_id: The external identifier for the related holdings record, can be used to retrieve records
- box_count: This box's position on the check-in card. Can be up to 120.
- enumeration: The series/volume/issue numbers for the current box
  - enumeration: A string representation of this data, suitable for public display
  - levels: An array of all values in the enumeration fields, including any `null` values, in their hierarchical order
- start_date: An ISO-8601 date representing the first date of coverage for the box
- end_date: An ISO-8601 date representing the end of the coverage for the box. `null` if the box represents a single date
- trans_start_date: An ISO-8601 date representing the start date of the transaction when the item was received
- trans_end_date: An ISO-8601 date representing the end date of the transaction. `null` if the transaction only covers a single date
- status: The current status of the box item
  - code: The single-character code provided that describes the current status of the box
  - label: A human-readable label for the code
- claim_count: An unclear counter for the number of "claims"
- copy_count: A integer providing the number of copies of the serial received for this box
- url: A URL to a digital version of the box holdings, not usually populated
- suppressed: A boolean flag for if this record should be suppressed in the front end
- note: A general note field describing the contents of the box entry
- staff_note: An internal note field not for public display

## Requirements

- ruby 2.7
- AWS CLI

## Dependencies

- nypl_ruby_util@0.0.3
- aws-sdk-s3@1.74.0
- rspec@3.9.0
- mocha@1.11.2
- rubocop@0.89.1
- sqlite3 (see below)

## Environment Variables

- AWS_REGION: Region where the function is deployed
- LOG_LEVEL: Standard log level setting
- SQLITE_BUCKET: S3 bucket where the sqlite file is stored
- SQLITE_FILE: Name of the sqlite file to create in `/tmp` and store in s3

## Installation

This function is developed using the AWS SAM framework, [which has installation instructions here](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html)

To install the dependencies for this function, they must be bundled for this framework and should be done with `rake run_bundler`

### Layers

This function uses a layer to include the `pg` and `sqlite3` dependencies because the AWS Lambda environment does not included the shared C/C++ libraries that they need to function. The layer is built on the `amazonlinux` docker image and from there deployed as a layer. This is also used in the SAM local environment for local runs (see the sam `YAML` files for how it is included).

## Usage

To run the function locally it may be invoked with rake, where FUNCTION is the name of the function you'd like to invoke from the `sam.local.yml` file:

`rake run_local`

## Testing

Testing is provided via `rspec` with `mocha` for stubbing/mocking. The test suite can be invoked with `rake test`

## Linting

Linting is mostly based upon the standard `rubocop` settings, with some local customizations. Linting can be run with `rake lint`
