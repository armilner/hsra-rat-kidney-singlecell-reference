#!/usr/bin/env Rscript

# run_azimuth_local_mapping.R
# Example workflow for annotating a query Seurat object using a
# local Azimuth-compatible rat kidney reference.

suppressPackageStartupMessages({
  library(Seurat)
  library(Azimuth)
})

# -----------------------------
# User inputs
# -----------------------------
reference_dir <- "path/to/azimuth_reference"
query_path <- "path/to/your_query_seurat.rds"
output_path <- "query_with_azimuth_labels.rds"

# -----------------------------
# Load query
# -----------------------------
query_obj <- readRDS(query_path)

if (!inherits(query_obj, "Seurat")) {
  stop("Query is not a Seurat object.")
}

# -----------------------------
# Run Azimuth local mapping
# -----------------------------
mapped <- RunAzimuth(
  query = query_obj,
  reference = reference_dir
)

# -----------------------------
# Save output
# -----------------------------
saveRDS(mapped, output_path)

message("Azimuth local mapping complete.")
message("Annotated Seurat object saved to: ", output_path)

# Print available predicted label columns if present
pred_cols <- grep("^predicted", colnames(mapped@meta.data), value = TRUE)
message("Predicted metadata columns found:")
print(pred_cols)

if ("predicted.celltype" %in% colnames(mapped@meta.data)) {
  print(table(mapped$predicted.celltype, useNA = "ifany"))
}