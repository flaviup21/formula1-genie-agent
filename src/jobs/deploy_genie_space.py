# Databricks notebook source
# MAGIC %md
# MAGIC # Create or update the Formula 1 Genie agent
# MAGIC Renders `src/genie/f1_genie_space.json` for the target catalog/schema and creates the Genie agent on
# MAGIC the first run. Its ID is kept in `/Volumes/<catalog>/<schema>/raw/genie_space_id`, so later runs update
# MAGIC that agent and never touch other agents with the same title. Runs after the gold tables and the
# MAGIC metric view exist, because the Genie API rejects agents whose tables are missing.

# COMMAND ----------

import json
from string import Template

from databricks.sdk import WorkspaceClient
from databricks.sdk.errors import NotFound

dbutils.widgets.text("catalog", "formula1")
dbutils.widgets.text("schema", "f1genie")
dbutils.widgets.text("template_path", "")
dbutils.widgets.text("title", "Formula 1 Race Analytics")
dbutils.widgets.text("warehouse_id", "")
dbutils.widgets.text("parent_path", "")
dbutils.widgets.text("document_volumes", "[]")

catalog = dbutils.widgets.get("catalog")
schema = dbutils.widgets.get("schema")
template_path = dbutils.widgets.get("template_path")
title = dbutils.widgets.get("title")
warehouse_id = dbutils.widgets.get("warehouse_id")
parent_path = dbutils.widgets.get("parent_path")
document_volumes = dbutils.widgets.get("document_volumes")

with open(template_path) as f:
    serialized_space = Template(f.read()).substitute(
        catalog=catalog, schema=schema, document_volumes=document_volumes
    )
json.loads(serialized_space)  # fail early on a broken template

description = (
    "Ask questions about Formula 1 history (1950-present): driver and constructor wins, podiums, points, "
    "championships, reliability, qualifying poles and pit stops. "
    f"Built on {catalog}.{schema} and the race_performance_metrics metric view"
    + (", plus the FIA Formula 1 regulation PDFs in the documents volume." if json.loads(document_volumes) else ".")
)

# COMMAND ----------

w = WorkspaceClient()
id_file = f"/Volumes/{catalog}/{schema}/raw/genie_space_id"


def stored_space_id():
    try:
        with open(id_file) as f:
            space_id = f.read().strip()
    except FileNotFoundError:
        return None
    try:
        w.api_client.do("GET", f"/api/2.0/genie/spaces/{space_id}")
        return space_id
    except NotFound:
        print(f"Genie agent {space_id} from {id_file} no longer exists, creating a new one")
        return None


body = {
    "title": title,
    "description": description,
    "warehouse_id": warehouse_id,
    "parent_path": parent_path,
    "serialized_space": serialized_space,
}

space_id = stored_space_id()
if space_id:
    w.api_client.do("PATCH", f"/api/2.0/genie/spaces/{space_id}", body=body)
    action = "updated"
else:
    w.workspace.mkdirs(parent_path)
    space_id = w.api_client.do("POST", "/api/2.0/genie/spaces", body=body)["space_id"]
    with open(id_file, "w") as f:
        f.write(space_id)
    action = "created"

url = f"{w.config.host.rstrip('/')}/genie/rooms/{space_id}"
print(f"Genie agent {action}: {url}")
dbutils.notebook.exit(json.dumps({"action": action, "space_id": space_id, "url": url}))
