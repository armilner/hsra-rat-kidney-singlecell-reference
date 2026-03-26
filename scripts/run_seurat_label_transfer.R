#!/usr/bin/env Rscript

# run_seurat_label_transfer.R
# Example workflow for annotating a query Seurat object using the
# HSRA rat kidney DietSeurat reference with Seurat label transfer.

suppressPackageStartupMessages({
  library(Seurat)
})

# -----------------------------
# User inputs
# -----------------------------
reference_path <- "path/to/hsra_kidney_reference_dietseurat.rds"
query_path <- "path/to/your_query_seurat.rds"
output_path <- "query_with_seurat_transfer_labels.rds"

# Number of dimensions to use
dims_use <- 1:30

# -----------------------------
# Load reference and query
# -----------------------------
ref <- readRDS(reference_path)
query_obj <- readRDS(query_path)

if (!inherits(ref, "Seurat")) {
  stop("Reference is not a Seurat object.")
}
if (!inherits(query_obj, "Seurat")) {
  stop("Query is not a Seurat object.")
}
if (!"celltype" %in% colnames(ref@meta.data)) {
  stop("Reference object does not contain a 'celltype' metadata column.")
}

# -----------------------------
# Prepare objects
# -----------------------------
DefaultAssay(ref) <- "RNA"
DefaultAssay(query_obj) <- "RNA"

# Query normalization/feature setup
query_obj <- NormalizeData(query_obj, verbose = FALSE)
query_obj <- FindVariableFeatures(query_obj, verbose = FALSE)

# -----------------------------
# Run anchor finding and transfer
# -----------------------------
anchors <- FindTransferAnchors(
  reference = ref,
  query = query_obj,
  dims = dims_use
)

predictions <- TransferData(
  anchorset = anchors,
  refdata = ref$celltype,
  dims = dims_use
)

query_obj <- AddMetaData(query_obj, metadata = predictions)

# -----------------------------
# Save output
# -----------------------------
saveRDS(query_obj, output_path)

message("Seurat label transfer complete.")
message("Annotated Seurat object saved to: ", output_path)

print(table(query_obj$predicted.id, useNA = "ifany"))