# DEPRECATED IN FAVOUR OF 
https://github.com/apollographql/apollo-codegen




# graphql-swift-codegen

[![Build Status](https://travis-ci.org/tberman/graphql-swift-codegen.svg?branch=master)](https://travis-ci.org/tberman/graphql-swift-codegen)

graphql-swift-codegen will generate swift code based on the schema provided.

## Install

Clone the repository and use `rake install` to build.

This will put the binary in `./build/graphql-swift-codegen/bin/`.

## Usage

```
$ graphql-swift-codegen url

Options:
  --path - Output path, default: .
  --username - HTTP Basic auth username
  --password - HTTP Basic auth password
  --bearer - HTTP Bearer auth token, eg: eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1N...
  --v - Add verbose output
  --r - Raw body (old GraphQL servers accept the query as a raw POST)
```
