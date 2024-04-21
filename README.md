# Action: Install Incus client

This action installs `incus-client` in the runner for the purpose of managing remote servers. Optionally, it can create a remote for you as well.

## Usage 
```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Install Incus client interface
      - uses: shellhazard/action-incus-client@v1
        with:
          remote_name: my_remote
          remote_host: my.incus.server.io:8443
          incus_client_cert: {{ secrets.INCUS_CLIENT_CERT }}
          incus_client_key: {{ secrets.INCUS_CLIENT_KEY }}
```

You may omit `remote_name`, in which case it will match `remote_host`.

You may also omit the port, which will default to `8443`.

## Generating certificates
To generate a new certificate pair, run on the Incus server to get a token:
```sh
incus config trust add gha-runner
```

Now you'll need another machine with Incus client installed and a network path to your server. If you're already authenticated, you'll want to move your certificate temporarily:
```sh
mv ~/.config/incus/client.crt ~/.config/incus/client.real.crt
mv ~/.config/incus/client.key ~/.config/incus/client.key.crt
```

Then run the following to regenerate them:
```sh
incus remote add temp --token=<output of above> --accept-certificates
```

Assuming everything was successful, you should have the authenticated certificate in `~/.config/incus` under `client.crt` and `client.key`. 

Create a new repository secret for the contents of each of the two files, then clean up:
```sh
rm ~/.config/incus/client.crt && rm ~/.config/incus/client.key

# Run the below commands if you moved your existing certificates earlier
mv ~/.config/incus/client.real.crt ~/.config/incus/client.crt 
mv ~/.config/incus/client.real.key ~/.config/incus/client.key 
```

## Using with Terraform
If you passed `remote_host`, all that's required for Terraform to be able to talk to your Incus server is to configure the provider:
```hcl
provider "incus" {
  accept_remote_certificate = true

  remote {
    name    = "my_remote"
    scheme  = "https"
    address = "my.incus.server.io"
    port    = "8443"
    default = true
  }
}
```

### Notes on Terraform Cloud
- If you are using Terraform Cloud, the execution mode for your workspace must be set to Local as the machine state of the runner is required for this action to work; i.e. your runner should be using the [Setup Terraform](https://github.com/hashicorp/setup-terraform) action and doing all the work itself, using TFC exclusively for state.
- If you're using the remote execution mode - you don't need this action, but there are some caveats that weren't obvious to me upfront:
  - Passing a token to the provider as [suggested in the provider documentation](https://registry.terraform.io/providers/lxc/incus/latest/docs) will lead to a misleading success on the first run, but failures in subsequent runs, as the token is consumed once the client certificates are generated. TFC runners are ephemeral so these certificates are lost after the run ends.
  - Instead, you should be able to use the [Local File](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) provisioner to create the expected certificates at `~/.config/incus/client.crt` and `~/.config/incus/client.key`.
  - The main downside of this approach is that you're forced to expose your Incus REST server to the internet, as there's no way to connect your TFC runner to i.e. your [Tailscale network](https://tailscale.com/) prior to execution. YMMV.
