# Security policy

Candle is a live service with real users. If you find a vulnerability, please
tell us privately first and give us time to fix it before you talk about it in
public.

## How to report

Use GitHub's private reporting: the **Security** tab of this repository →
**Report a vulnerability**. Only the maintainers see the report.

Please **do not** open a public issue, pull request or discussion about a
vulnerability, and do not post details in chats.

A useful report includes:

- what is affected (API endpoint, app screen, bot command, Mini App);
- steps to reproduce, or a proof of concept;
- what an attacker could do with it;
- the app version or commit you tested (Settings → About Candle → Copy).

## What happens next

- We confirm we received the report within 7 days.
- We keep you updated while we work on a fix.
- After the fix is deployed, we publish an advisory and credit you, unless you
  prefer not to be named.

Candle is a small volunteer project: we have no bug bounty.

## Rules for testing

- Test against your own local setup (`make dev`, see `docs/development.md`)
  whenever possible.
- On the production service (`candle.vyachdiliger.com`, the apps and the
  Telegram bot), use only your own accounts and data. Do not access, change or
  delete other users' data, do not send spam, and do not run load or denial of
  service tests.
- Stop and report as soon as you see data that is not yours.

## Scope

In scope: the code in this repository and the services built from it (API,
web app, Android and iOS apps, Telegram bot and Mini App).

Out of scope: third-party services we use (Telegram, Google sign-in, map
tiles), and findings that need a rooted or compromised device.

## Secrets

Never commit secrets, keys or tokens. If you notice one in the repository or its
history, report it the same way, privately.
