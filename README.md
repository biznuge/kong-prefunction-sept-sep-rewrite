# Kong pre-function for Sept / /Sep CLDR fix

After experiencing a problem with dates provided from unicode / CLDR which brings back a short code of "Sept" rather than "Sep" (migrating from Java 11 - 17 among other languages like PHP) for the pattern dd-MMM-yyyy, I decided to take a look at whether this could be fixed tactically in Kong API Gateway, for organisations that have an API Gateway capability at their disposal.

This isn't intended as a permanent strategic fix, but could be useful tactially in reducing pressure on a team while returning service for customers more quickly than a full rollback or fix forward.

Use case is where an API contract might have been broken as a result of an upgrade where edge cases may cause issues not covered by existing test cases.

## The Kong Pre-Function Plugin

- https://github.com/Kong/kong/blob/master/kong/plugins/pre-function/_schema.lua
- https://www.toolify.ai/ai-news/understanding-phases-and-plugins-in-kong-api-gateway-601448

Would love to find better docs from somewhere, but for now I've pieced enough together to make this work. Phase document is particularly useful in understanding what this plugin does.

This plugin allows access to phases of the kong request lifecycle, such as  `certificate`, `rewrite`, `access`, `header_filter`, `body_filter`, and `log`.". The example here uses the "Access" phase to intercept incoming POST params, rewrite Sept to Sep, and then continues on with the rest of the lifecycle.

Check out the config/kong.yml file.

## Kong Docker Installation

You can install kong-dbless as testing only requires a single config to perform test. This means no need for a Postgres docker.

Obviously (or maybe not), you'll need Docker installed to run this, and the main script is intended for use on MacOS (tested on a 2021 Apple Silicon M1, and partially on an Ubuntu 20 machine).

https://docs.konghq.com/gateway/latest/install/docker/

## Config / Kongfig :|

The **./config/kong.yaml** configuration file contains a pre-function plugin config with embedded lua to transform -Sept- to -Sep- within the request body of a payload.

## Running the demo (on MacOS)

You can use the run_mac.sh script located in the root of this repo to run test.

This script will:
- Grab your local IP address to route between docker and your machine
- Install Kong Docker (default is 2.8 or you can speify 3.4 or 3.10 on command line)
- Start a Node test server
- Run a test script which outputs to the console
- Tear Kong Docker and Node server down for you

## Running the tests

Open up a terminal on MacOS. Kong 2.8 is the default version, so just running the bash script will test with 2.8.

### For Kong 2.8

> ./run_mac.sh

### For Kong 3.4

If you want to test with 3.4 or 3.10 just add "3.4" or "3.10" to the end of the script.

> ./run_mac.sh 3.4

> ./run_mac.sh 3.10

Only these 3 versions of Kong are included (both LTS versions) as I needed to cherry pick the versions of Kong I wanted to test. You could easily add more by tweaking run_mac.sh.






