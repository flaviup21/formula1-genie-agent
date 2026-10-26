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
# Files are fetched one by one: right after a dataset update Kaggle may not have built the
# full archive yet (/datasets/download/{dataset} returns 404 "No gcs url found"), while the
# individual files are already available.
for name in sorted(EXPECTED_FILES):
    url = f"https://www.kaggle.com/api/v1/datasets/download/{dataset}/{name}"
    req = urllib.request.Request(url, headers={"User-Agent": "databricks-f1genie"})
    with urllib.request.urlopen(req, timeout=300) as resp:
        payload = resp.read()

    # Kaggle may serve large single files zip-compressed
    if payload[:4] == b"PK\x03\x04":
        with zipfile.ZipFile(io.BytesIO(payload)) as zf:
            payload = zf.read(zf.namelist()[0])

    dest = os.path.join(target_dir, name)
    with open(dest, "wb") as out:
        out.write(payload)
    print(f"  {dest} ({len(payload) / 1e6:.1f} MB)")

dbutils.notebook.exit(f"Downloaded {len(EXPECTED_FILES)} CSV files to {target_dir}")
