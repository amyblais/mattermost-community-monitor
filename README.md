# Mattermost Community Monitor

Mattermost has an [official community monitoring process](https://docs.mattermost.com/process/community-process.html) that ensures that issues from users are reviewed. The third set of items on that list is a great opportunity for automation, because the systems we have to check all have APIs, the criteria for including an issue or post are very clearly defined, and the checks happen periodically.

## How to set up monitoring

Because this uses standard HTTP requests you can run it from any machine that's connected to the Internet, inlcuding your workstation

1. Check out this repository
2. Run `bundle` to install required Ruby gems
3. Copy `sample.conf.yaml` to `conf.yaml` and add the correct configuration values

Now you can run the script manually with `./main.rb` or by adding this crontab entry to run this every week on Wednesday:

```
0 9 * * 3 /path/to/main.rb
```

## How it works

For each repository in each group the `main.rb`, the script requests the latest issues and then filters them based on a couple criteria. First, it removes issues reported by Mattermost staff, and then compares the current date with the last modified date. If it matches, it adds it to the issues to report and then sends that report to the user in individual messages to avoid exceeding the character limit for Mattermost messages.

## More Info

Using [HTTParty](https://github.com/jnunemaker/httparty) it's easy to create a tiny custom API wrapper that handles authenticating against the API if necessary and formatting the responses to work well with your script.

The file `lib/mattermost_api.rb` also contains a good reference for both authenticating against Mattermost by caching the authentication token, and how to send a direct message between users using the [Mattermost API](https://api.mattermost.com/).
