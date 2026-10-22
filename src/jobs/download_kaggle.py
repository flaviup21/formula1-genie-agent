# Databricks notebook source
# MAGIC %md
# MAGIC # Download Kaggle F1 race data
# MAGIC Downloads the latest version of the Kaggle dataset (default `jtrotman/formula-1-race-data`)
# MAGIC and extracts its CSV files into `/Volumes/<catalog>/<schema>/raw/kaggle/`
# MAGIC (schema and volume are deployed by the bundle).

# COMMAND ----------

import io
import os
import urllib.request
import zipfile

dbutils.widgets.text("catalog", "formula1")
dbutils.widgets.text("schema", "f1genie")
dbutils.widgets.text("dataset", "jtrotman/formula-1-race-data")

catalog = dbutils.widgets.get("catalog")
schema = dbutils.widgets.get("schema")
dataset = dbutils.widgets.get("dataset")

EXPECTED_FILES = {
    "circuits.csv", "constructor_results.csv", "constructor_standings.csv", "constructors.csv",
    "driver_standings.csv", "drivers.csv", "lap_times.csv", "pit_stops.csv", "qualifying.csv",
    "races.csv", "results.csv", "seasons.csv", "sprint_results.csv", "status.csv",
}

# COMMAND ----------

target_dir = f"/Volumes/{catalog}/{schema}/raw/kaggle"
os.makedirs(target_dir, exist_ok=True)

# COMMAND ----------

# Public datasets can be downloaded anonymously; the API redirects to a signed storage URL.
url = f"https://www.kaggle.com/api/v1/datasets/download/{dataset}"
req = urllib.request.Request(url, headers={"User-Agent": "databricks-f1genie"})
with urllib.request.urlopen(req, timeout=300) as resp:
    payload = resp.read()
print(f"Downloaded {len(payload) / 1e6:.1f} MB from {url}")

with zipfile.ZipFile(io.BytesIO(payload)) as zf:
    csv_members = [m for m in zf.namelist() if m.lower().endswith(".csv")]
    missing = EXPECTED_FILES - {os.path.basename(m) for m in csv_members}
    if missing:
        raise RuntimeError(f"Kaggle archive is missing expected files: {sorted(missing)}")
    for member in csv_members:
        dest = os.path.join(target_dir, os.path.basename(member))
        with zf.open(member) as src, open(dest, "wb") as out:
            out.write(src.read())
        print(f"  {dest}")

dbutils.notebook.exit(f"Extracted {len(csv_members)} CSV files to {target_dir}")
