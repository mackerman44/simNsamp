#' @title simNsamp: Simple Simulation and Sampling
#'
#' @description A simple function to simulate a population and then sample that population at varying sample sizes to
#' determine sample sizes needed to achieve a given coefficient of variation
#'
#' @param groups the groups
#' @param groupProps the group proportions
#' @param sampleSizes the sample sizes to be evaluated
#' @param bootstraps the desired number of bootstraps
#' @param simulation the desired number of simulations
#' @param alpha the desired alpha
#'
#' @author Mike Ackerman
#'
#' @examples simNsamp
#'
#' @export
#' @return NULL

simNsamp <- function(groups = c("jack","2ocean","3ocean","4ocean"), groupProps = c(.10,.35,.54,.01),
                     sampleSizes = seq(20,100,20), bootstraps = 100, simulations = 10, alpha = 0.10)
{
  # Create a blank data frame to store results (group columns x sampleSize rows)
  cvTable <- as.data.frame(matrix(rep(NA,(length(groups)*length(sampleSizes))),length(sampleSizes),length(groups)))
  names(cvTable) <- groups
  row.names(cvTable) <- sampleSizes

  # Blank vector of tables
  ciTables <- vector(mode = "list", length = length(sampleSizes))

  # Start program
  for(n in sampleSizes)
  {
    # Creating blank table to
    ciTable <- as.data.frame(matrix(rep(NA,(length(groups)*simulations)),simulations,length(groups)*3))
    nG <- length(groups)
    cn <- NULL
    for (g in 1:nG) cn <- c(cn, groups[g], paste(groups[g], "L", sep = ""), paste(groups[g], "U", sep = ""))
    colnames(ciTable) <- cn

    # Simulation loop
    for (s in 1:simulations)
    {
      propTable        <- as.data.frame(matrix(rep(NA, (bootstraps*length(groups))), bootstraps, length(groups)))
      names(propTable) <- groups

      groupPropCumul <- groupProps[1]
      for (i in 2:length(groupProps))
      {
        groupPropCumul <- c(groupPropCumul, sum(groupPropCumul[i-1], groupProps[i]))
      }
      # Bootstrap loop
      for (b in 1:bootstraps)
      {
        x <- runif(n) # Generate random numbers between 0 and 1

        # loop through ages
        for (q in 1:length(groups))
        {
          # if value is < cumulative proportion assign to age and tally
          propTable[b,q] <- length(which(x <= groupPropCumul[q])) / n
          x[which(x<=groupPropCumul[q])] <- groups[q]
        } # End loop through group
      } # End bootstrap loop

      tick1 <- seq(1, nG*3, 3)
      tick2 <- tick1 + 1
      tick3 <- tick2 + 1

      ciTable[s,tick1] <- apply(propTable, 2, mean)
      ciTable[s,tick2] <- apply(propTable, 2, quantile, alpha/2)
      ciTable[s,tick3] <- apply(propTable, 2, quantile, 1-(alpha/2))
      ciTableName <- paste("ciTable", n, sep = "")
      assign(ciTableName, ciTable)
    } # End simulation loop

  # fill in cvTable with CV for each age
  cvTable[which(row.names(cvTable)==n),] <- (apply(propTable,2,sd) / apply(propTable,2,mean)) * 100
  ciTables[[n/unique(diff(sampleSizes))]] <- ciTable
  } # End loop through sample sizes

  write.csv(cvTable, file = "cvTable.csv")
} # End simNsamp function


