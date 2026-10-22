# Databricks notebook source
# MAGIC %md
# MAGIC # Create race_performance_metrics metric view
# MAGIC Renders `src/metric_views/race_performance_metrics.yaml` for the target catalog/schema
# MAGIC and (re)creates the Unity Catalog metric view on top of the pipeline's gold tables.

# COMMAND ----------

from string import Template

dbutils.widgets.text("catalog", "formula1")
dbutils.widgets.text("schema", "f1genie")
dbutils.widgets.text("template_path", "")

catalog = dbutils.widgets.get("catalog")
schema = dbutils.widgets.get("schema")
template_path = dbutils.widgets.get("template_path")

with open(template_path) as f:
    yaml_body = Template(f.read()).substitute(catalog=catalog, schema=schema)

# COMMAND ----------

view_name = f"`{catalog}`.`{schema}`.race_performance_metrics"
spark.sql(f"CREATE OR REPLACE VIEW {view_name}\nWITH METRICS\nLANGUAGE YAML\nAS $$\n{yaml_body}\n$$")

# Smoke test: the view must resolve and return data
row = spark.sql(f"SELECT MEASURE(race_starts) AS starts, MEASURE(wins) AS wins FROM {view_name}").first()
print(f"{view_name}: race_starts={row.starts}, wins={row.wins}")
if not row.starts:
    raise RuntimeError(f"{view_name} returned no rows")
