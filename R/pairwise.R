

fac2cont.cor <- function(x, y)
{
  if(length(levels(as.factor(x))) > 100) return(NA_real_)

  fit <- lm(y ~ as.factor(x))
  return(sqrt(summary(fit)$r.squared))
}

cramersV <- function(x, y, correct=FALSE, ...)
{
  if(length(x) != length(y)) stop("vectors must have the same length")
  stat <- chisq.test(x, y, correct = correct, ...)$statistic
  denom <- length(x) * (min(length(unique(x)), length(unique(y))) - 1)
  return(as.numeric(sqrt(stat/denom)))
}

my_correlation <- function(x, y, data, ...)
{
  dat <- na.exclude(data[c(x, y)])
  x <- dat[[x]]
  y <- dat[[y]]

  if(nrow(dat) < 4 || length(unique(x)) < 2 || length(unique(y)) < 2) return(NA_real_)
  if(is.numericish(x) && is.numericish(y)) return(cor(as.numeric(x), as.numeric(y), use = 'pairwise'))
  if(!is.numericish(x) && !is.numericish(y)) return(cramersV(x, y))
  if(is.numericish(x) && !is.numericish(y))
  {
    tmp <- x
    x <- y
    y <- tmp
  }
  return(fac2cont.cor(x, as.numeric(y)))
}

do_all_correlations <- function(dat)
{
  combinations <- as.data.frame(t(combn(names(dat), m = 2)), stringsAsFactors = FALSE)
  out <- mapply(my_correlation, combinations$V1, combinations$V2, MoreArgs = list(data = dat))
  names(out) <- paste(combinations$V1, "and", combinations$V2)
  return(out[order(abs(out), decreasing = TRUE, na.last = TRUE)])
}



corr_miss <- function(dat)
{
  # correlations of missings
  dat.na <- is.na(dat)
  idx <- 0 < colSums(dat.na) & colSums(dat.na) < nrow(dat)
  if(sum(idx) < 2) return(NULL)
  cor.miss <- cor(dat.na[, idx])
  cor.miss <- reshape2::melt(cor.miss)[as.vector(upper.tri(cor.miss, diag = FALSE)), ]
  out <- cor.miss$value
  names(out) <- paste(cor.miss$Var1, "and", cor.miss$Var2)
  out[order(abs(out), decreasing = TRUE, na.last = TRUE)]
}

pairwise <- function(dat)
{
  structure(list(
    correlation = do_all_correlations(dat),
    correlation.nas = corr_miss(dat)
  ), class = "dq_pairwise")
}

format.dq_pairwise <- function(x, digits = 3, ...)
{
  data.frame(
    correlation = paste0(names(x$correlation), " (", formatC(x$correlation, digits = digits, format = "f"), ")"),
    correlation.nas = c(paste0(names(x$correlation.nas), " (", formatC(x$correlation.nas, digits = digits, format = "f"), ")"),
                        rep("", times = length(x$correlation) - length(x$correlation.nas)))
  )
}