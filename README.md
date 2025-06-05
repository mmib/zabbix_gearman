## Zabbix Gearman Monitoring

This repo gives you an **out-of-the-box** way to monitor every Gearman function with Zabbix:

```
zabbix_gearman/
├── scripts/
│   ├── gearman_lld.sh          # low-level discovery (JSON)
│   └── gearman_status.sh       # queued / running / workers counters
├── templates/
│   ├── gearman_monitoring.yaml         # passive-agent version (default)
│   └── gearman_monitoring_active.yaml  # active-agent version
└── zabbix_agentd.d/
    └── template_gearman.conf   # UserParameter definitions
```

---

### 1  Prerequisites

| Component                             | Version tested                                    |
| ------------------------------------- | ------------------------------------------------- |
| **Zabbix Server / Proxy**             | 6.0 LTS – 7.2.4                                   |
| **Zabbix Agent 2** (or classic agent) | any matching build                                |
| **Gearman**                           | `gearmand` 1.1.x (`gearadmin` must be in `$PATH`) |
| Host OS                               | Debian/Ubuntu/RHEL-like (bash + awk available)    |

> The scripts assume **Gearman listens on `localhost:4730`**.
> If yours is different, edit the keys in the YAML template *and* the UserParameter line endings (`...localhost,4730`).

---

### 2  Install on the host that runs Gearman workers

```bash
# 1. Clone or copy this folder
git clone https://github.com/mmib/zabbix_gearman.git
cd zabbix_gearman

# 2. Install scripts
sudo mkdir -p /etc/zabbix/scripts
sudo cp scripts/gearman_*.sh /etc/zabbix/scripts/
sudo chmod +x /etc/zabbix/scripts/gearman_*.sh

# 3. Enable UserParameters
sudo cp zabbix_agentd.d/template_gearman.conf /etc/zabbix/zabbix_agentd.d/

# 4. Restart agent
sudo systemctl restart zabbix-agent   # or zabbix-agent2
```

---

### 3  Import the template into Zabbix

1. **Configuration → Templates → Import**
2. Choose **YAML** → upload **templates/gearman\_monitoring.yaml**
   *(pick `gearman_monitoring_active.yaml` if your agent is set to “active only”).*
3. You’ll see **Template App Gearman** in *Templates/App* group.

---

### 4  Link the template to the host

*Configuration → Hosts → click your Gearman host → Templates tab → Link new templates → choose **Template App Gearman** → Update.*

---

### 5  How it works

| Item key                     | What it returns                      | Polling |
| ---------------------------- | ------------------------------------ | ------- |
| `gearman.lld[host,port]`     | JSON list of `{#GMFUNC}` values      | 60 s    |
| `gearman.queued[{#GMFUNC}]`  | Jobs waiting in queue                | 30 s    |
| `gearman.running[{#GMFUNC}]` | Jobs currently running               | 30 s    |
| `gearman.workers[{#GMFUNC}]` | Workers registered for that function | 30 s    |

#### Triggers (prototype → one per function)

| Severity    | Condition                    | Default                  |
| ----------- | ---------------------------- | ------------------------ |
| **High**    | No workers for 5 min         | `min(300)<1`             |
| **Average** | Jobs queued but none running | `queued>0 and running=0` |
| **Warning** | Backlog > 100 (10 min avg)   | `avg(600)>100`           |

Adjust thresholds by editing the trigger prototypes after import.

---

### 6  Smoke test

```bash
# From the Zabbix host
zabbix_get -s <agent_ip> -k 'gearman.lld[localhost,4730]'

# Should output valid JSON. Then:
zabbix_get -s <agent_ip> -k 'gearman.workers["some:function",localhost,4730]'
```

Within two discovery cycles (≤ 2 minutes) you’ll see items in *Monitoring → Latest data* and triggers in *Monitoring → Problems*.

---

### 7  Customising

* **Different Gearman host/port** – change the keys in both YAML template and `template_gearman.conf`.
* **Active-only agent** – import `gearman_monitoring_active.yaml` instead.
* **Backlog threshold** – edit the “backlog too large” trigger prototype.

---

### 8  Uninstall

```bash
# Remove template link in Zabbix UI first,
# then on the host:
sudo rm /etc/zabbix/scripts/gearman_*.sh
sudo rm /etc/zabbix/zabbix_agentd.conf.d/template_gearman.conf
sudo systemctl restart zabbix-agent
```

---

Happy queue-watching! If you hit any issues, open an Issue or PR.

