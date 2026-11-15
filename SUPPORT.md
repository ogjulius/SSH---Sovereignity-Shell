# Getting help

| You want to… | Go to |
|---|---|
| Install SSH | [Installation guides](docs/installation/README.md) |
| Fix something that isn't working | [Troubleshooting](docs/TROUBLESHOOTING.md), then search [issues](https://github.com/ogjulius/SSH---Sovereignity-Shell/issues) |
| Report a bug | [Bug report](https://github.com/ogjulius/SSH---Sovereignity-Shell/issues/new?template=bug_report.yml) — include `ssh-shell status` |
| Suggest a feature | [Feature request](https://github.com/ogjulius/SSH---Sovereignity-Shell/issues/new?template=feature_request.yml) |
| Report a vulnerability | Privately, see [SECURITY.md](SECURITY.md) |
| Contribute | [CONTRIBUTING.md](CONTRIBUTING.md) |

SSH is an alpha, volunteer-run project. Please check
[docs/installation/COMPATIBILITY.md](docs/installation/COMPATIBILITY.md) to see
what is actually tested on your setup before reporting.

Before filing a report, collect:

```sh
ssh-shell status          # SSH's own view (remove window titles if private)
qs --version
hyprctl version   # or: niri msg version
```
