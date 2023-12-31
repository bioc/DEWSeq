
#' @export
#' @importFrom methods as is
#' @importFrom BiocGenerics sort
#' @importFrom GenomeInfoDb sortSeqlevels
#' @importFrom GenomicRanges makeGRangesFromDataFrame
#' @importFrom SummarizedExperiment SummarizedExperiment
#'
#' @title create DESeq data object
#' @description create DESeq data object from sliding window counts,
#' phenotype data and annotation data
#'
#' @details
#' If \code{annotObj} is a file name, the input file MUST be <TAB> separated, and supports reading in .gz files. \cr
#' If \code{annotObj} is a data.frame, \code{colnames(annotObj)} MUST not be empty.\cr
#' This function checks for the following columns after reading in the file or on data.frame:
#' \itemize{
#'   \item \code{chromosome}: chromosome name
#'   \item \code{unique_id}: unique id of the window, \code{rownames(object)} must match this column
#'   \item \code{begin}: window start co-ordinate, see parameter \code{start0based}
#'   \item \code{end}: window end co-ordinate
#'   \item \code{strand}: strand
#'   \item \code{gene_id}: gene id
#'   \item \code{gene_name}: gene name
#'   \item \code{gene_type}: gene type annotation
#'   \item \code{gene_region}: gene region
#'   \item \code{Nr_of_region}: number of the current region
#'   \item \code{Total_nr_of_region}: total number of regions
#'   \item \code{window_number}: window number
#' }
#'
#' This function creates a \code{\link[DESeq2:DESeqDataSet]{DESeqDataSet}} using supplied countData, phenotype data
#' and annotation data. The chromosomal locations and annotations of the sliding windows
#' (parsed from \code{annotObj}) can be accessed from the returned object using: \code{rowRanges(object)}
#'
#' @param countData \code{data.frame} or \code{matrix}, sliding window count data
#' @param colData \code{DataFrame} or \code{data.frame}, phenotype data,
#' see \code{\link[DESeq2:DESeqDataSet]{DESeqDataSet}}
#' @param annotObj \code{data.frame} or \code{character}, can either be a data.frame or a file name,
#' see details
#' @param design \code{formula} or \code{matrix}, design of the experiment,
#' see \code{\link[DESeq2:DESeqDataSet]{DESeqDataSet}}
#' @param tidy \code{logical}, If TRUE, first column is of countData is treated as rownames
#' (defalt: FALSE), see \code{\link[DESeq2:DESeqDataSet]{DESeqDataSet}}
#' @param ignoreRank \code{logical}, ignore rank, see \code{\link[DESeq2:DESeqDataSet]{DESeqDataSet}}
#' @param start0based \code{logical}, TRUE (default) or FALSE.
#' If TRUE, then the start positions in \code{annotObj} is  considered to be 0-based
#'
#' @examples
#'
#' data("SLBP_K562_w50s20")
#' slbpDat <- counts(SLBP_K562_w50s20)
#' phenoDat <- DataFrame(conditions=as.factor(c(rep('IP',2),'SMI')),
#' row.names = colnames(slbpDat))
#' phenoDat$conditions <- relevel(phenoDat$conditions,ref='SMI')
#' annotDat <- as.data.frame(rowRanges(SLBP_K562_w50s20))
#' # by default chromsome column is 'seqnames'
#' # and begin co-ordinate column is 'start'
#' # rename these columns
#' colnames(annotDat)[1:2] <- c('chromosome','begin')
#' slbpDds <- DESeqDataSetFromSlidingWindows(countData = slbpDat,
#' colData = phenoDat,annotObj = annotDat,design=~conditions)
#'
#' @return DESeq object
DESeqDataSetFromSlidingWindows <- function(countData, colData, annotObj,
                                           design, tidy=FALSE,
                                           ignoreRank=FALSE, start0based=TRUE){
  stopifnot(ncol(countData) > 1)
  if(is(countData,'data.table') ||is(countData,'tbl') ){
    countData <- data.frame(countData)
    warning('countData is a data.table or tibble object, converting it to data.frame. First column will be used as rownames')
    if(!tidy){
      tidy <- TRUE
    }
  }
  if (tidy) {
    # this code is copied from DESeq2 source, credits to authors
    rownms <- as.character(countData[,1])
    countData <- countData[,-1,drop=FALSE]
    rownames(countData) <- rownms
  }else if(is.null(rownames(countData))){
    stop('rownames of countData cannot be empty')
  }
  if(is(annotObj,"character")){
    annotData <- .readAnnotation(fname=annotObj,asGRange=FALSE,start0based=start0based)
  }else if(is(annotObj,"data.frame")){
    if(is(annotObj,'data.table') ||is(annotObj,'tbl') ){
      annotObj <- data.frame(annotObj)
    }
    neededCols <- c('chromosome','unique_id','begin','end','strand','gene_id','gene_name','gene_type','gene_region','Nr_of_region',
                    'Total_nr_of_region','window_number')
    missingCols <- setdiff(neededCols,colnames(annotObj))
    if(length(missingCols)>0){
      stop('Input annotation data.frame is missing required columns, needed columns:
         chromosome: chromosome name
         unique_id: unique id of the window
         begin: window start co-ordinate
         end: window end co-ordinate
         strand: strand
         gene_id: gene id
         gene_name: gene name
         gene_type: gene type annotation
         gene_region: gene region
         Nr_of_region: number of the current region
         Total_nr_of_region: total number of regions
         window_number: window number
         Missing columns:
         ',paste(missingCols,collapse=", "),'')
    }
    annotData <- annotObj
    rownames(annotData) <- annotData$unique_id
  }else{
    stop('annotObj MUST be a data.frame or character')
  }
  if(length(intersect(as.character(annotData$unique_id),rownames(countData)))==0){
    stop('There are no common unique ids between the countData and annotObj. Please check your data sets!')
  }else if(length(setdiff(rownames(countData),rownames(annotData)))>0){
    warning('Cannot find chromosomal positions for all entries in countData.
            countData rows with missing annotation will be removed !')
  }
  commonIds <- intersect(rownames(annotData),rownames(countData))
  countData <- countData[commonIds,]
  annotData <- annotData[commonIds,]
  # The code below is copied from DESeq2 source, credits to authors
  if (is(colData,"data.frame")){
    colData <- as(colData, "DataFrame")
  }
  # check if the rownames of colData are simply in different order
  # than the colnames of the countData, if so throw an error
  # as the user probably should investigate what's wrong
  if (!is.null(rownames(colData)) & !is.null(colnames(countData))) {
    if (all(sort(rownames(colData)) == sort(colnames(countData)))) {
      if (!all(rownames(colData) == colnames(countData))) {
        stop(paste("rownames of the colData:
  ",paste(rownames(colData),collapse=","),"
  are not in the same order as the colnames of the countData:
  ",paste(colnames(countData),collapse=",")))
      }
    }
  }
  if (is.null(rownames(colData)) & !is.null(colnames(countData))) {
    rownames(colData) <- colnames(countData)
  }
  # assemble summarized experiment
  gr <- makeGRangesFromDataFrame(df=annotData,seqnames.field='chromosome',start.field='begin',
                                       end.field='end',strand.field='strand',
                                       keep.extra.columns=TRUE,starts.in.df.are.0based=start0based)

  gr <- sortSeqlevels(gr)
  gr <- sort(gr)
  countData <- as.matrix(countData[as.character(mcols(gr)$unique_id),])
  se <- SummarizedExperiment(assays = SimpleList(counts=countData),colData = colData,rowRanges=gr)
  return(DESeqDataSet(se, design = design, ignoreRank))
}


#' @export
#' @importFrom methods as is
#' @importFrom data.table fread
#' 
#' @title  filter count data
#' @description In addition to count data matrix, htseq-clip also creates a max count matrix.\cr
#' For each window, this file contains the maximum crosslink site count (height)  calculated \cr
#' per nucleotide. This function uses this file to filter the count data file instead of the \cr
#' default prefiltering on \code{rowSums}. Windows failing the threshold \cr
#' \code{rowSums(maxWindowCount>=countThresh)>=nSamples} will be removed from the object. 
#' 
#' @param object \code{DESeqDataSet}, see \code{\link{DESeqDataSetFromSlidingWindows}}
#' @param maxCountFile \code{character} file name/path to max count matrix
#' @param countThresh \code{numeric} max count threshold
#' @param nsamples \code{numeric} number of samples where the max count value must be\cr
#' >= countThresh
#'
#' @return DESeq object
filterCounts <- function(object, maxCountFile, countThresh, nsamples){
  maxCounts <- fread(maxCountFile)
  if(nsamples>ncol(maxCounts)){
    stop("nsamples cut-off given: ",nsamples, " is > number of columns in ",maxCountFile,": ",ncol(maxCounts))
  }
  windowIds <- maxCounts[rowSums(maxCounts>=countThresh)>=nsamples,][[1]]
  commonIds <- intersect(rownames(object), windowIds)
  if(length(commonIds)==0){
    stop("There are no common windowIds between the given DESeq object and the file ", maxCountFile)
  }
  return(object[commonIds,])
}
