# Production Deployment

This directory deploys `mail-manager` to the VPS with the same image-pull workflow used by the CLIProxyAPI stack.

## Server Layout

```text
/opt/mail-manager/
  .env
  compose.production.yml
  data/
  scripts/remote-deploy.sh
```

The deployment workflow uploads this directory to `/opt/mail-manager`, then runs `scripts/remote-deploy.sh`.
The script preserves the server `.env` file and only creates it on the first deploy.

## Runtime

- Image: `ghcr.io/dovelanlan/mail-manager`
- Container: `mail-manager`
- Data: `/opt/mail-manager/data:/app/data`
- Private URL: `http://100.67.99.9:18500`

The first deploy generates `LOGIN_PASSWORD` and `SECRET_KEY` in `/opt/mail-manager/.env`.
Keep `SECRET_KEY` stable. Changing it will make stored encrypted credentials unreadable.

If the GHCR package is private, set `GHCR_USERNAME` and `GHCR_TOKEN` in `/opt/mail-manager/.env`.
Public GHCR packages do not need registry credentials on the VPS.

## GitHub Secrets

The production deployment workflow expects these repository or organization secrets:

- `PRODUCTION_SSH_PRIVATE_KEY`
- `PRODUCTION_SSH_KNOWN_HOSTS`

`PRODUCTION_SSH_KNOWN_HOSTS` can be generated with:

```bash
ssh-keyscan -H 23.175.201.12
```
