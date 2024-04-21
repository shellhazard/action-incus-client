# Action: Install Incus client

This action installs `incus-client` in the runner for the purpose of managing remote servers.

## Usage 
```yaml
jobs:
	test:
		runs-on: ubuntu-latest
		steps:
			- uses: actions/checkout@v4

			- uses: shellhazard/action-incus-client@v1
			  with:
			  	remote_host: {{ https://my.incus.server.io }}
			  	incus_client_cert: {{ secrets.INCUS_CLIENT_CERT }}
			  	incus_client_key: {{ secrets.INCUS_CLIENT_KEY }}

			# Execute commands with `sudo incus x`
```