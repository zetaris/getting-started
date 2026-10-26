# Run Zetaris on GitHub Codespaces (Experimental)

> **Experimental:** Codespaces can require additional Docker networking configuration. This guide includes troubleshooting steps for container connections and S3 access.

Use a Codespace to run Zetaris in your browser without installing Docker on your computer. You need a GitHub account and access to [Zetaris Cloud](https://cloud.enterprise.zetaris.com/dashboard/download).

Follow sections 1–7 to open Zetaris and use SQL. Sample datasets are optional and need internet access from the Docker containers.

## 1. Create a repository and Codespace

1. On GitHub, create a new **private repository**, for example `zetaris-codespace`.
2. Select **Add a README file** so the repository has a branch. Leave it otherwise empty; do not upload the platform to GitHub.
3. Open [GitHub Codespaces](https://github.com/codespaces) and select **New codespace**.
4. Choose your new repository and its `main` branch.
5. Choose a region and the **4-core · 16 GB RAM · 32 GB** machine type.
6. Check which account will pay, then select **Create codespace**.
7. When the browser editor opens, trust the folder if prompted and open **Terminal → New Terminal**.

Codespaces uses your GitHub allowance and may incur charges. See [GitHub's billing guide](https://docs.github.com/en/billing/concepts/product-billing/github-codespaces).

## 2. Upload the platform

On your computer, download `zetaris-platform.zip` from Zetaris Cloud's **Run locally** page.

In the Codespace terminal, keep the platform folder and zip out of version control before uploading them:

```bash
printf '\n/zetaris-platform*/\n/zetaris-platform*.zip\n' >> .git/info/exclude
```

In the Codespace Explorer, right-click the workspace folder and select **Upload…**. Upload the zip, then run:

```bash
unzip -q zetaris-platform.zip
cd zetaris-platform
```

You can also drag an already unpacked folder into the Explorer. Include all its files, including the hidden `.env` file. If the folder has a different name, use that name in the `cd` command and put quotes around names with spaces.

Run the remaining commands from the platform folder, where `docker-compose.yml` is located. Keep the platform files and credentials in the Codespace; do not commit or push them to GitHub.

Restore script permissions after uploading:

```bash
chmod +x preflight.sh verify.sh
find init initdb -type f -name '*.sh' -exec chmod +x {} +
```

## 3. Sign in to the image registry

Copy the registry sign-in command from Zetaris Cloud's **Run locally** page and run it in the Codespace terminal. Keep the credentials private.

Wait for `Login Succeeded`. Sign-in is once per machine: signing in on your laptop does not sign in the Codespace. If preflight still reports that you are not signed in to `zetarishackathon.azurecr.io`, check that you ran the supplied command in this Codespace, as the same user running Docker. Do not print or share Docker's credential configuration.

Then run:

```bash
./preflight.sh
```

Fix any **FAIL** messages before continuing. Allow at least 15 GB of free disk space for the installation. If a command says `Permission denied`, repeat the permission commands in section 2.

## 4. Set the browser address

1. Open the editor's **Ports** panel, next to **Terminal**.
2. Select **Add Port** and enter `3000`.
3. Keep its visibility set to **Private**.
4. Copy its **Forwarded Address**.

If adding the port does nothing, reload the browser editor, wait for it to reconnect, then add `3000` again.

Open the platform's `.env` file and replace the existing `GUI_URL` and `ALLOWED_ORIGINS` values with that address:

```dotenv
GUI_URL=https://<codespace-name>-3000.app.github.dev
ALLOWED_ORIGINS=https://<codespace-name>-3000.app.github.dev
```

Replace `<codespace-name>` with your own Codespace name. Remove any trailing `/`. Keep `UI_PORT=3000` and leave the other supplied settings unchanged.

## 5. Download the images and start Zetaris

```bash
docker compose config --quiet
docker compose pull
docker compose up -d postgres driver api ui
```

Downloading and starting can take several minutes. This starts the core platform and its `init` setup job. The driver creates the administrator account. `init` finishes with `Exited (0)`, which is normal. Leave sample loading until section 8.

If the driver stays at **Waiting** or **health: starting**, follow the firewall steps below. Otherwise, continue to section 7.

## 6. Fix a driver connection timeout

Open another terminal and enter the platform folder. Read the driver logs:

```bash
docker compose logs --tail=20 driver
```

If they repeatedly show `Cannot create PoolableConnectionFactory` and `Connect timed out`, check the database connection:

```bash
docker compose exec -T driver bash -c 'getent hosts postgres; timeout 4 bash -c "</dev/tcp/postgres/5432"; echo TCP_EXIT=$?'
docker compose exec -T postgres pg_isready -h postgres -U zetaris -d metastore
```

If the first command shows a Postgres address and `TCP_EXIT=124`, while the second says `accepting connections`, inspect the firewall:

```bash
sudo iptables -S FORWARD
sudo iptables -S DOCKER-FORWARD
sudo iptables-legacy -S FORWARD
```

A legacy `FORWARD` policy of `DROP`, with rules for `docker0` but none for the Zetaris bridge, can block the containers from reaching each other even when the newer Docker rules allow it.

For this specific problem, allow traffic within the Zetaris bridge. Run these commands in the same terminal:

```bash
ZETARIS_NETWORK_ID=$(docker network inspect zetaris_default --format '{{.Id}}')
ZETARIS_BRIDGE="br-${ZETARIS_NETWORK_ID:0:12}"
ip link show "$ZETARIS_BRIDGE"
```

Continue only if the interface exists. If you changed the Compose project name, use its network name instead of `zetaris_default`.

```bash
sudo iptables-legacy -C FORWARD -i "$ZETARIS_BRIDGE" -o "$ZETARIS_BRIDGE" -j ACCEPT 2>/dev/null ||
  sudo iptables-legacy -I FORWARD 1 -i "$ZETARIS_BRIDGE" -o "$ZETARIS_BRIDGE" -j ACCEPT

docker compose up -d postgres driver api ui
```

This rule allows traffic only within this Docker bridge. Keep the browser port private; do not disable the firewall or change its global policy.

Repeat the driver's TCP probe from above. It should now show `TCP_EXIT=0`. The driver may recover on its next connection attempt; check its logs and container health before restarting anything.

If the problem returns after restarting the Codespace or recreating the network, repeat these steps. To remove the rule, use the same terminal variables:

```bash
sudo iptables-legacy -D FORWARD -i "$ZETARIS_BRIDGE" -o "$ZETARIS_BRIDGE" -j ACCEPT
```

## 7. Open Zetaris

Check the services:

```bash
docker compose ps -a
```

Wait for `postgres`, `driver`, `api` and `ui` to be healthy. If one fails, read its logs with `docker compose logs --tail=20 SERVICE`, replacing `SERVICE` with its name.

1. In **Ports**, open the private forwarded address for `3000`.
2. Sign in with the platform account shown on Zetaris Cloud's **Run locally** page, or your configured administrator account. This is separate from your Zetaris Cloud login.
3. Open **Workbench → SQL Workspace → New Query**.
4. Enter `SELECT 7 AS seven` and select **Execute**.

Keep port `3000` private. In **Ports**, right-click each unwanted port and select **Stop Forwarding Port**. Codespaces can automatically forward internal ports as services start, including `4040`, `8888`, `8889`, `10000` and dynamically assigned ports for Postgres and the driver. Browser use needs only `3000`; removing these extra forwards leaves the containers running.

## 8. Load sample datasets (optional)

The `NY_TAXI` and `TPCDS_DB` samples use files in Amazon S3. First, make sure the driver can reach S3:

```bash
docker compose exec -T driver curl --connect-timeout 5 --max-time 15 -I https://s3.amazonaws.com/
```

An HTTP response, including `405 Method Not Allowed`, means the driver can reach S3. If the command reports a DNS error or times out, follow the diagnostics below before loading samples. The bridge rule in section 6 only allows communication between containers; it does not fix outbound internet access.

### 8.1 Fix blocked outbound DNS and HTTPS

Compare the host and driver container:

```bash
getent ahostsv4 s3.amazonaws.com
curl --connect-timeout 5 --max-time 15 -I https://s3.amazonaws.com/
docker compose exec -T driver cat /etc/resolv.conf
ip -4 route show default
sudo iptables-legacy -S FORWARD
```

Docker's `nameserver 127.0.0.11` is its internal DNS proxy. Look for the `ExtServers` comment to identify its upstream resolver; use that address, not `127.0.0.11`. The default route shows the outbound interface after `dev`.

To distinguish a DNS failure from blocked HTTPS, resolve an S3 address on the host and supply it to the container's HTTPS probe:

```bash
ZETARIS_S3_IP=$(getent ahostsv4 s3.amazonaws.com | awk 'NR == 1 {print $1}')
test -n "$ZETARIS_S3_IP" && docker compose exec -T driver \
  curl --connect-timeout 5 --max-time 15 \
  --resolve "s3.amazonaws.com:443:$ZETARIS_S3_IP" -I https://s3.amazonaws.com/
```

If the host reaches S3, but the container's normal probe times out resolving DNS and this probe also times out connecting, inspect the legacy `FORWARD` rules. A `DROP` policy with rules for `docker0` but no outbound rules for the Zetaris bridge can block these connections. Apply the following only for that case.

In the same terminal, identify the bridge again and set the confirmed resolver and outbound interface. If your Compose project name differs, replace `zetaris_default`:

```bash
ZETARIS_NETWORK_ID=$(docker network inspect zetaris_default --format '{{.Id}}')
ZETARIS_BRIDGE="br-${ZETARIS_NETWORK_ID:0:12}"
ip link show "$ZETARIS_BRIDGE"

# Enter the upstream DNS address and interface shown by the diagnostics above.
read -r -p "Upstream DNS address from ExtServers: " ZETARIS_DNS
read -r -p "Outbound interface from the default route: " ZETARIS_OUTBOUND_IF
ip link show "$ZETARIS_OUTBOUND_IF"
```

Continue only if both interfaces exist and the resolver matches your container's upstream DNS. These rules allow DNS only to that resolver, outbound HTTPS, and established/related return traffic for this bridge. They keep the global `DROP` policy and do not open public inbound ports:

```bash
for ZETARIS_DNS_PROTOCOL in udp tcp; do
  sudo iptables-legacy -C FORWARD -i "$ZETARIS_BRIDGE" -o "$ZETARIS_OUTBOUND_IF" \
    -d "$ZETARIS_DNS" -p "$ZETARIS_DNS_PROTOCOL" --dport 53 -j ACCEPT 2>/dev/null ||
  sudo iptables-legacy -I FORWARD 1 -i "$ZETARIS_BRIDGE" -o "$ZETARIS_OUTBOUND_IF" \
    -d "$ZETARIS_DNS" -p "$ZETARIS_DNS_PROTOCOL" --dport 53 -j ACCEPT
done

sudo iptables-legacy -C FORWARD -i "$ZETARIS_BRIDGE" -o "$ZETARIS_OUTBOUND_IF" \
  -p tcp --dport 443 -j ACCEPT 2>/dev/null ||
sudo iptables-legacy -I FORWARD 1 -i "$ZETARIS_BRIDGE" -o "$ZETARIS_OUTBOUND_IF" \
  -p tcp --dport 443 -j ACCEPT

sudo iptables-legacy -C FORWARD -i "$ZETARIS_OUTBOUND_IF" -o "$ZETARIS_BRIDGE" \
  -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT 2>/dev/null ||
sudo iptables-legacy -I FORWARD 1 -i "$ZETARIS_OUTBOUND_IF" -o "$ZETARIS_BRIDGE" \
  -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
```

Repeat the original S3 probe **without** `--resolve`. Continue only once it returns an HTTP response. Do not disable the firewall, change the global forwarding policy or add an unrestricted forwarding rule. These runtime rules may need reapplying after a Codespace restart; recreating the Docker network can change its bridge name. Recheck the interfaces and resolver first.

To undo only these outbound rules later, use the same variable values and the rule specifications above with `-D FORWARD` in place of `-I FORWARD 1`. Removing them can break external data queries; no container teardown is required.

### 8.2 Load the samples

Once the connection works, start sample loading:

```bash
docker compose up -d bootstrap
docker compose logs --tail=20 bootstrap
```

Allow a few minutes for it to finish. `bootstrap` should end with `Exited (0)`. If it stays at `registering the sample datasets`, check S3 access again rather than waiting indefinitely.

You can stop a stalled sample job while keeping the core platform running:

```bash
docker compose stop bootstrap
```

After sample loading finishes, run `./verify.sh`. If you chose to skip samples, that script will report that `bootstrap` never ran; this does not by itself mean the core services failed.

In **SQL Workspace**, run these examples individually to read the CSV and Parquet samples, group items by category, and join sales to items:

```sql
SHOW LIGHTNING DATABASES;

SELECT * FROM NY_TAXI.taxi_zones LIMIT 5;

SELECT i_item_sk, i_item_id, i_current_price, i_category
FROM TPCDS_DB.item LIMIT 5;

SELECT i_category, COUNT(*) AS items,
       ROUND(AVG(i_current_price), 2) AS avg_price
FROM TPCDS_DB.item
GROUP BY i_category ORDER BY items DESC;

SELECT i.i_item_id, s.ss_quantity, s.ss_sales_price
FROM TPCDS_DB.store_sales s JOIN TPCDS_DB.item i
ON s.ss_item_sk = i.i_item_sk LIMIT 5;
```

Continue with [Start here](../../START-HERE.md) for SQL and data-source instructions. Recipes using the supplied samples need this optional setup to finish first.

## 9. Stop and resume

To stop Zetaris and keep its data:

```bash
docker compose stop
```

Then open [your Codespaces list](https://github.com/codespaces), select **…** next to the Codespace and choose **Stop codespace**. This stops compute charges. Storage can still incur charges while the Codespace exists. Closing the browser tab alone does not stop it.

To resume, open the Codespace from the list, wait for the editor to reconnect, enter the platform folder and run:

```bash
docker compose up -d postgres driver api ui
```

If the page stays at **Stopping codespace…**, return to the Codespaces list and refresh it. Wait for stopping to finish before reopening. Avoid repeatedly starting and stopping it. If the state does not clear, use [GitHub Support](https://support.github.com/).

If the driver cannot reach Postgres after resuming, repeat section 6. If S3 access fails, repeat the diagnostics in section 8.1 and reapply the scoped rules only if needed. Reload the editor if its forwarded port is missing. Start `bootstrap` separately only if you want to load samples.

## 10. Clear Zetaris data

**This deletes the local Zetaris databases, uploaded data, accounts and encryption keys. Back up anything you want to keep first. External data sources are not deleted.**

From the platform folder, run:

```bash
docker compose down -v
```

This removes the platform containers and their data volumes. It keeps the downloaded images and bundle files. To also remove the platform's container images, use this instead:

```bash
docker compose down -v --rmi all
```

To start a fresh installation, run `docker compose up -d postgres driver api ui` again. If you removed the images, run `docker compose pull` first. If you hit a connection timeout, follow section 6 again because the new Docker network may have a different bridge name.

## 11. Delete the entire Codespace

**Deleting a Codespace permanently removes its files and local data, including anything you have not saved elsewhere.**

1. Download any files or backups you want to keep. Keep credentials out of GitHub commits.
2. Open [your Codespaces list](https://github.com/codespaces).
3. Find the correct Codespace, select **…**, then **Delete**.
4. Confirm deletion if prompted and check that it disappears from the list.

Deleting the Codespace removes its compute and storage, so you do not need to clear Docker separately first. It leaves the GitHub repository in place. See [GitHub's deletion guide](https://docs.github.com/en/codespaces/developing-in-a-codespace/deleting-a-codespace).
