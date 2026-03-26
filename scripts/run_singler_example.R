#!/usr/bin/env Rscript

# run_singler_example.R
# Example workflow for annotating a query dataset using the
# HSRA rat kidney aggregated SingleR reference.

suppressPackageStartupMessages({
  library(SingleR)
  library(SingleCellExperiment)
  library(Seurat)
})

# -----------------------------
# User inputs
# -----------------------------
reference_path <- "path/to/hsra_kidney_reference_sce_agg.rds"
query_path <- "path/to/your_query_object.rds"
output_path <- "query_with_SingleR_labels.rds"

# Set this to TRUE if your query object is already a SingleCellExperiment.
query_is_sce <- FALSE

# If query_is_sce = FALSE, this script assumes the query is a Seurat object
# with an RNA assay and joined layers.
# The output saved will be the annotated Seurat object.

# -----------------------------
# Load reference
# -----------------------------
ref <- readRDS(reference_path)

if (!"celltype" %in% colnames(colData(ref))) {
  stop("Reference object does not contain a 'celltype' column in colData.")
}

# -----------------------------
# Load query
# -----------------------------
query_obj <- readRDS(query_path)

if (query_is_sce) {
  query_sce <- query_obj
} else {
  if (!inherits(query_obj, "Seurat")) {
    stop("Query object is not a Seurat object. Set query_is_sce = TRUE if using SCE input.")
  }
  
  DefaultAssay(query_obj) <- "RNA"
  
  # Join layers for Seurat v5 objects if needed.
  query_obj <- JoinLayers(query_obj, assay = "RNA")
  
  query_counts <- LayerData(query_obj, assay = "RNA", layer = "counts")
  query_logcounts <- LayerData(query_obj, assay = "RNA", layer = "data")
  
  query_sce <- SingleCellExperiment(
    assays = list(
      counts = query_counts,
      logcounts = query_logcounts
    ),
    colData = query_obj@meta.data
  )
}

# -----------------------------
# Run SingleR
# -----------------------------
pred <- SingleR(
  test = query_sce,
  ref = ref,
  labels = ref$celltype
)

# -----------------------------
# Output
# -----------------------------
if (query_is_sce) {
  colData(query_sce)$SingleR_label <- pred$labels
  colData(query_sce)$SingleR_pruned <- pred$pruned.labels
  
  saveRDS(query_sce, output_path)
  
  message("SingleR annotation complete.")
  message("Annotated SingleCellExperiment saved to: ", output_path)
  print(table(query_sce$SingleR_label, useNA = "ifany"))
} else {
  query_obj$SingleR_label <- pred$labels
  query_obj$SingleR_pruned <- pred$pruned.labels
  
  saveRDS(query_obj, output_path)
  
  message("SingleR annotation complete.")
  message("Annotated Seurat object saved to: ", output_path)
  print(table(query_obj$SingleR_label, useNA = "ifany"))
}

