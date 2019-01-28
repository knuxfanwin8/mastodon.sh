# mastodon.sh

Experimental API library for Mastodon.

## Usage

Place mastodon.sh in your application's folder, then use `source ./mastodon.sh client_id client_secret auth_token` to load mastodon.sh.

This loads all of the Mastodon.sh functions.
Use those functions from within your script, but don't forget to set the variables, like so:

```bash
source ./mastodon.sh client_id client_secret auth_token
content="This is a test of the mastodon.sh library."
media="test.jpg"
write_status
```
