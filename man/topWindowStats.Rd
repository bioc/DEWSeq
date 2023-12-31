% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/topWindow.R
\name{topWindowStats}
\alias{topWindowStats}
\title{stats for the top windows in each region}
\usage{
topWindowStats(
  windowRes,
  padjCol = "padj",
  padjThresh = 0.05,
  log2FoldChangeCol = "log2FoldChange",
  log2FoldChangeThresh = 1,
  start0based = TRUE,
  normalizedCounts,
  treatmentCols,
  treatmentName = "treatment",
  controlName = "control",
  op = "max"
)
}
\arguments{
\item{windowRes}{\code{data.frame}, output from \code{\link{resultsDEWSeq}}}

\item{padjCol}{\code{character}, name of the adjusted pvalue column (default: padj)}

\item{padjThresh}{\code{numeric}, threshold for p-adjusted value (default: 0.05)}

\item{log2FoldChangeCol}{\code{character}, name of the log2foldchange column (default: log2FoldChange)}

\item{log2FoldChangeThresh}{\code{numeric}, threshold for log2foldchange value (default:1)}

\item{start0based}{\code{logical}, TRUE (default) or FALSE. If TRUE, then the start positions in \code{windowRes} is  considered to be 0-based}

\item{normalizedCounts}{\code{data.frame} or \code{matrix}, normalized read counts per window. \code{rownames(normalizedCounts)} and \code{unique_id} column from \code{windoeRes} must match
see \code{\link[DESeq2:counts]{counts}}, \code{\link[DESeq2:vst]{vst}} or \code{\link[DESeq2:rlog]{rlog}}}

\item{treatmentCols}{\code{character vector}, column names in \code{normalizedCounts} for treatment/case samples. The remaining columns in the data.frame will be considered control samples}

\item{treatmentName}{\code{character}, treatment name, see Details  (default: treatment)}

\item{controlName}{\code{character}, control name, see Details (default: control)}

\item{op}{\code{character}, can be one of \code{max} (default) or \code{min}. \code{max} returns windows with maximum log2FoldChange and mean normalized expression in the \code{treatmentCols} columns,
\code{min} returns windows with minimum log2FoldChange and mean normalized expression}
}
\value{
data.frame
}
\description{
given window resutls and normalized counts, combine significant overlapping windows into regions and
for each region, pick two candidate winodws:
\enumerate{
 \item with highest log2FoldChange and
 \item with highest normalized mean in treatment samples (see parameter \code{treatmentCols})
}
Return a data.frame with region information and stats, and for the selected windows, the following information:
\itemize{
 \item \code{unique_id} of the window
 \item start and end co-ordinates
 \item log2FoldChange
 \item normalized mean expression in treatment and control samples and
 \item individual normalized expression in replicates
}
}
\details{
The output data.frame of this function has the following columns:
\itemize{
 \item \code{chromosome}: chromosome name
 \item \code{gene_id}: gene id
 \item \code{gene_name}: gene name
 \item \code{gene_region}: gene region
 \item \code{gene_type}: gene type annotation
 \item \code{regionStartId}: \code{unique_id} of the left most window, where a enriched region begins
 \item \code{region_begin}: start position of the enriched region
 \item \code{region_end}: end position of the enriched region
 \item \code{region_length}: length of the enrched region
 \item \code{strand}: strand info
 \item \code{Nr_of_region}: number of the current region
 \item \code{Total_nr_of_region}: total number of regions
 \item \code{log2FoldChange_min}: min. log 2 fold change in the region
 \item \code{log2FoldChange_mean}: average log 2 fold change in the region
 \item \code{log2FoldChange_max}: max. log 2 fold change in the region
 \item \code{unique_id.log2FCWindow}: unique_id of the window with largest log2FoldChange
 \item \code{begin.log2FCWindow}: start position of the window with largest log2FoldChange
 \item \code{end.log2FCWindow}: end of the window with largest log2FoldChange
 \item \code{log2FoldChange.log2FCWindow}: log2FoldChange  of the window with largest log2FoldChange
 \item \code{treatmentName.mean.log2FCWindow}: mean of the normalized expression of the treatment samples for log2FCWindow, names in \code{treatmentCols} are used to calculate mean and treatmentName is from the parameter \code{treatmentName}
 \item \code{controlName.mean.log2FCWindow}: mean of the normalized expression of the control samples for log2FCWindow, \code{colnames(normalizedCounts)} not found in \code{treatmentCols} are used to calculate mean and controlName is from the parameter \code{controlName}
 \item the next columns will be normalized expression values  of the log2FCWindow from individual treatment and control samples.
 \item \code{unique_id.meanWindow}:  unique_id of the window with largest mean in all treatment samples from \code{treatmentCols}
 \item \code{begin.meanWindow}: start position of the mean window
 \item \code{end.meanWindow}:  end position of the mean window
 \item \code{log2FoldChange.meanWindow}:log2FoldChange of the mean window
 \item \code{treatmentName.mean.meanWindow}: mean of the normalized expression of the treatment samples for meanWindow, names in \code{treatmentCols} are used to calculate mean and treatmentName is from the parameter \code{treatmentName}
 \item \code{controlName.mean.meanWindow}: mean of the normalized expression of the control samples for log2FCWindow, \code{colnames(normalizedCounts)} not found in \code{treatmentCols} are used to calculate mean and controlName is from the parameter \code{controlName}
 \item the next columns will be normalized expression values  of the meanWindow from individual treatment and control samples
}
}
\examples{

data(slbpWindows)
data(slbpVst)
slbpList <- topWindowStats(slbpWindows,padjCol = 'pSlidingWindows.adj',
normalizedCounts = slbpVst, treatmentCols = c('IP1','IP2'),
treatmentName = 'SLBP',controlName = 'SMI')

}
