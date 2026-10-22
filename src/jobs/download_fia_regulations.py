# Databricks notebook source
# MAGIC %md
# MAGIC # Download FIA Formula 1 regulations
# MAGIC Crawls the paginated FIA regulation listing (category 110 = Formula 1) and downloads every
# MAGIC regulation PDF for season `min_year` or later into `/Volumes/<catalog>/<schema>/documents/`.
# MAGIC Files that already exist in the volume are skipped, so reruns only fetch new issues.

# COMMAND ----------

import os
import re
import time
import urllib.parse
import urllib.request

dbutils.widgets.text("catalog", "formula1")
dbutils.widgets.text("schema", "f1genie")
dbutils.widgets.text("listing_url", "https://www.fia.com/regulation/category/110")
dbutils.widgets.text("min_year", "2026")
dbutils.widgets.text("max_pages", "20")

catalog = dbutils.widgets.get("catalog")
schema = dbutils.widgets.get("schema")
listing_url = dbutils.widgets.get("listing_url")
min_year = int(dbutils.widgets.get("min_year"))
max_pages = int(dbutils.widgets.get("max_pages"))

target_dir = f"/Volumes/{catalog}/{schema}/documents"
HEADERS = {"User-Agent": "Mozilla/5.0 (compatible; databricks-f1genie)"}
PDF_LINK = re.compile(r'href="([^"]+\.pdf)"', re.IGNORECASE)
YEAR = re.compile(r"(?<!\d)(19[5-9]\d|20\d\d)(?!\d)")


def fetch(url: str) -> bytes:
    req = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(req, timeout=120) as resp:
        return resp.read()


def regulation_year(file_name: str):
    # The first 4-digit year in the file name is the season the regulation applies to,
    # e.g. fia_2026_f1_regulations_-_section_c_technical_-_iss_21_-_2026-10-19.pdf -> 2026
    m = YEAR.search(file_name)
    return int(m.group(1)) if m else None

# COMMAND ----------

# Collect PDF links from all listing pages until a page yields nothing new
pdf_urls = {}
for page in range(max_pages):
    html = fetch(f"{listing_url}?page={page}").decode("utf-8", errors="replace")
    new = 0
    for href in PDF_LINK.findall(html):
        url = urllib.parse.urljoin(listing_url, href)
        name = urllib.parse.unquote(os.path.basename(urllib.parse.urlparse(url).path))
        if name not in pdf_urls:
            pdf_urls[name] = url
            new += 1
    print(f"page {page}: {new} new PDF links")
    if new == 0:
        break

selected = {n: u for n, u in pdf_urls.items() if (regulation_year(n) or 0) >= min_year}
print(f"{len(pdf_urls)} PDFs listed, {len(selected)} for season >= {min_year}")

# COMMAND ----------

os.makedirs(target_dir, exist_ok=True)
downloaded, skipped, failed = [], 0, []
for name, url in sorted(selected.items()):
    dest = os.path.join(target_dir, name)
    if os.path.exists(dest):
        skipped += 1
        continue
    try:
        data = fetch(url)
        with open(dest, "wb") as out:
            out.write(data)
        downloaded.append(name)
        print(f"  downloaded {name} ({len(data) / 1e6:.1f} MB)")
        time.sleep(0.5)  # be polite to fia.com
    except Exception as e:  # keep going; one broken link should not fail the refresh
        failed.append(name)
        print(f"  FAILED {name}: {e}")

summary = f"downloaded={len(downloaded)} skipped_existing={skipped} failed={len(failed)}"
print(summary)
if selected and len(failed) == len(selected):
    raise RuntimeError("All FIA regulation downloads failed")
dbutils.notebook.exit(summary)
