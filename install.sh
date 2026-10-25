#!/usr/bin/env bash
# Matrix Host MOTD installer
# Usage: curl -fsSL https://raw.githubusercontent.com/Intruder-tech/Modt-bash-/main/install.sh | sudo bash
set -e

if [ "$(id -u)" -ne 0 ]; then
    echo "This installer must run as root. Use: curl -fsSL <url> | sudo bash" >&2
    exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 is required but not installed." >&2
    exit 1
fi

# Remove old Matrix Host MOTD scripts
rm -f /etc/profile.d/matrix-motd.sh
rm -f /etc/profile.d/00-matrix-motd.sh
rm -f /etc/profile.d/99-matrix-motd.sh

# Install the new MOTD renderer
cat > /usr/local/bin/matrix-motd <<'MATRIX_PY'
#!/usr/bin/env python3
import os, time, socket, platform, subprocess, shutil

R="\033[0m"
C="\033[38;5;81m"
W="\033[38;5;252m"
D="\033[38;5;245m"
G="\033[38;5;114m"
Y="\033[38;5;221m"
COLORS=[60,111,81,183,212,221,114,204]

def cmd(s):
    try:
        return subprocess.check_output(
            s, shell=True, text=True,
            stderr=subprocess.DEVNULL, timeout=3
        ).strip()
    except Exception:
        return "N/A"

def color(n):
    return "\033[38;5;%dm" % n

def size(n):
    n=float(n)
    for unit in ("B","KB","MB","GB","TB","PB"):
        if n < 1024 or unit == "PB":
            return "%.1f %s" % (n,unit)
        n /= 1024

fox = [
"⠀⠀⠀⠀⣀⡀",
"⠀⠀⠀⠀⣿⠙⣦⠀⠀⠀⠀⠀⠀⣀⣤⡶⠛⠁",
"⠀⠀⠀⠀⢻⠀⠈⠳⠀⠀⣀⣴⡾⠛⠁⣠⠂⢠⠇",
"⠀⠀⠀⠀⠈⢀⣀⠤⢤⡶⠟⠁⢀⣴⣟⠀⠀⣾",
"⠀⠀⠀⠠⠞⠉⢁⠀⠉⠀⢀⣠⣾⣿⣏⠀⢠⡇",
"⠀⠀⡰⠋⠀⢰⠃⠀⠀⠉⠛⠿⠿⠏⠁⠀⣸⠁",
"⠀⠀⣄⠀⠀⠏⣤⣤⣀⡀⠀⠀⠀⠀⠀⠾⢯⣀",
"⠀⠀⣻⠃⠀⣰⡿⠛⠁⠀⠀⠀⢤⣀⡀⠀⠺⣿⡟⠛⠁",
"⠀⡠⠋⡤⠠⠋⠀⠀⢀⠐⠁⠀⠈⣙⢯⡃⠀⢈⡻⣦",
"⢰⣷⠇⠀⠀⠀⢀⡠⠃⠀⠀⠀⠀⠈⠻⢯⡄⠀⢻⣿⣷",
"⠀⠉⠲⣶⣶⢾⣉⣐⡚⠋⠀⠀⠀⠀⠀⠘⠀⠀⡎⣿⣿⡇",
"⠀⠀⠀⠀⠀⣸⣿⣿⣿⣷⡄⠀⠀⢠⣿⣴⠀⠀⣿⣿⣿⣧",
"⠀⠀⠀⢀⣴⣿⣿⣿⣿⣿⠇⠀⢠⠟⣿⠏⢀⣾⠟⢸⣿⡇",
"⠀⠀⢠⣿⣿⣿⣿⠟⠘⠁⢠⠜⢉⣐⡥⠞⠋⢁⣴⣿⣿⠃",
"⠀⠀⣾⢻⣿⣿⠃⠀⠀⡀⢀⡄⠁⠀⠀⢠⡾ᵇʸ ᵗⁿᵏᵃ⠁",
"⠀⠀⠃⢸⣿⡇⠀⢠⣾⡇⢸⡇⠀⠀⠀⡞",
"⠀⠀⠀⠈⢿⡇⡰⠋⠈⠙⠂⠙⠢",
"⠀⠀⠀⠀⠈⢧"
]

osdata={}
try:
    for line in open("/etc/os-release"):
        if "=" in line:
            k,v=line.rstrip().split("=",1)
            osdata[k]=v.strip('"')
except Exception:
    pass

mem={}
for line in open("/proc/meminfo"):
    a=line.split()
    if len(a)>1:
        mem[a[0].rstrip(":")]=int(a[1])*1024

total=mem.get("MemTotal",0)
used=total-mem.get("MemAvailable",0)
swap_total=mem.get("SwapTotal",0)
swap_used=swap_total-mem.get("SwapFree",0)
disk=shutil.disk_usage("/")
up=int(float(open("/proc/uptime").read().split()[0]))
ip=cmd("hostname -I").split()
ip=ip[0] if ip else "N/A"
cpu=cmd("awk -F: '/model name|Hardware/ {print $2; exit}' /proc/cpuinfo").strip()
cores=os.cpu_count() or 1
load=" ".join(open("/proc/loadavg").read().split()[:3])
processes=sum(x.isdigit() for x in os.listdir("/proc"))
users=cmd("who | wc -l")
interfaces=", ".join(
    x.split(":")[0].strip()
    for x in open("/proc/net/dev").readlines()[2:]
    if ":" in x and x.split(":")[0].strip()!="lo"
) or "N/A"

a=list(map(int,open("/proc/stat").readline().split()[1:]))
time.sleep(0.15)
b=list(map(int,open("/proc/stat").readline().split()[1:]))
dt=sum(b)-sum(a)
cpu_usage="%.1f%%" % max(0,min(100,100*(1-(b[3]-a[3])/dt))) if dt else "N/A"

rows=[
("OS",osdata.get("PRETTY_NAME","Linux")),
("Kernel",platform.release()),
("Architecture",platform.machine()),
("CPU",(cpu or "Unknown").strip()),
("CPU Cores",str(cores)),
("CPU Usage",cpu_usage),
("RAM", "%s / %s (%d%%)" % (size(used),size(total),used*100//total if total else 0)),
("Swap","%s / %s (%d%%)" % (size(swap_used),size(swap_total),swap_used*100//swap_total if swap_total else 0)),
("Disk", "%s / %s (%d%%)" % (size(disk.used),size(disk.total),disk.used*100//disk.total)),
("Disk Free",size(disk.free)),
("IP Address",ip),
("Interfaces",interfaces),
("Uptime","%dd %dh %dm" % (up//86400,(up%86400)//3600,(up%3600)//60)),
("Load Average",load),
("Processes",str(processes)),
("Logged Users",users),
("Server Time",cmd("date '+%d %b %Y %H:%M:%S %Z'"))
]

print()
print(color(111)+"  "+socket.gethostname()+"@matrixhost"+R+
      " "+D+"-"*45+" Matrix Host"+R)
print()

for i in range(max(len(fox),len(rows))):
    left=color(COLORS[i%len(COLORS)])+fox[i]+R if i<len(fox) else ""
    right=""
    if i<len(rows):
        k,v=rows[i]
        shade=Y if k in ("RAM","Swap","Disk","CPU Usage") else C
        right=shade+"%-14s"%k+R+" "+W+str(v)+R
    print(left+" " * max(2,57-len(fox[i]) if i<len(fox) else 2)+right)

print()
print("  "+" ".join(color(c)+"●"+R for c in COLORS))
print()
print("  "+color(111)+"Matrix Host"+R+"  "+D+"| Premium Hosting Infrastructure"+R)
print("  "+D+"Support: support@matrixhost.in  |  https://matrixhost.in"+R)
print()
MATRIX_PY

chmod 755 /usr/local/bin/matrix-motd

# Remove old custom login hooks that invoke Matrix MOTD
for f in /etc/profile.d/*.sh; do
    [ -f "$f" ] || continue
    case "$f" in
        /etc/profile.d/00-matrix-motd.sh|/etc/profile.d/99-matrix-motd.sh)
            rm -f "$f" ;;
    esac
done

# Disable Ubuntu/Debian dynamic MOTD scripts
if [ -d /etc/update-motd.d ]; then
    chmod a-x /etc/update-motd.d/* 2>/dev/null || true
fi

# Disable SSH's separate static MOTD output
mkdir -p /etc/ssh/sshd_config.d
printf 'PrintMotd no\n' > /etc/ssh/sshd_config.d/99-matrix-motd.conf

# Run the custom banner once per SSH login
cat > /etc/profile.d/00-matrix-motd.sh <<'PROFILE'
if [ -n "$SSH_CONNECTION" ] && [ -z "$MATRIX_MOTD_SHOWN" ]; then
    export MATRIX_MOTD_SHOWN=1
    /usr/local/bin/matrix-motd
fi
PROFILE

chmod 644 /etc/profile.d/00-matrix-motd.sh

python3 -m py_compile /usr/local/bin/matrix-motd
/usr/local/bin/matrix-motd
echo "Matrix Host MOTD installed and tested."
