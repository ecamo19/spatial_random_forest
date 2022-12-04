#Measuring the functional redundancy of biological communities: a quantitative 
#guide

#   -----------------------------------------------------------------------
#R function “uniqueness” for calculating the species-level coefficients   
#and Vi and the community-level coefficients N (species richness), 
#Q (quadratic diversity), D (Simpson diversity), and U (uniqueness).

# Arguments ---------------------------------------------------------------
#comm: A matrix or a data frame of N plots × S species containing the 
#abundance  or incidence (0/1) of all species in the in plots. Columns are 
#species and plots are rows 

#dis: An object of class 'dist' containing the functional distances among 
#species

#tol: A tolerance threshold (a value less than tol is considered as null)

#abundance	A logical. If TRUE abundance data are used when available; 
#if FALSE incidence (0/1) data are used.



# Output ------------------------------------------------------------------

#Output: the function uniqueness returns a list of three data frames. 

#The  first data frame named Kbar gives values for Ki’s per species (rows) 
#and community (columns). 

#The second data frame named V gives values for Vi’s per species (rows) and 
#community (columns). 

#The third data set gives values for coefficients N (species richness), 
#Q (quadratic diversity),D (Simpson diversity), and U (uniqueness) per 
#community; in this third data  frame coefficients are columns and 
#communities are rows, the coefficients  are thus calculated per community 
#only.


# Function Syntax ---------------------------------------------------------

uniqueness <- function(comm, dis, tol = 1e-8, abundance = TRUE){
  
  if(!is.null(colnames(comm)) & !is.null(attributes(dis)$Labels)){
    if(any(!colnames(comm)%in%attributes(dis)$Labels)) stop("One or several species in comm are not in dis; check species names in comm and in dis")
    else dis <- as.dist(as.matrix(dis)[colnames(comm), colnames(comm)])
  }
  else if(ncol(comm)!=attributes(dis)$Size) stop("the number of species in comm must be equal to that in dis") 		
  
  D <- as.matrix(dis)
  if(!abundance){
    comm[comm>0] <- 1
  }
  commt <- as.data.frame(t(comm))
  
  funK <- function(v){
    p <- v/sum(v)
    K <- apply(D, 1, function(x) sum(x*p))
    K[p<tol] <- NA
    return(K)
  }
  V <- cbind.data.frame(sapply(commt, funK))
  rownames(V) <- colnames(comm)
  colnames(V) <- rownames(comm)
  funKbar <- function(v){
    p <- v/sum(v)
    Kbar <- sapply(1:nrow(D), function(i) sum(D[i,]*v/sum(v[-i])))
    Kbar[p<tol] <- NA
    return(Kbar)
  }
  Kbar <- cbind.data.frame(sapply(commt, funKbar))
  rownames(Kbar) <- colnames(comm)
  colnames(Kbar) <- rownames(comm)
  funQ <- function(v){
    p <- v/sum(v)
    Q <- t(p)%*%D%*%p
    return(Q)
  }
  Q <- unlist(sapply(commt, funQ))
  
  funSim <- function(v){
    p <- v/sum(v)
    S <- 1-sum(p^2)
    return(S)
  }
  Sim <- unlist(sapply(commt, funSim))
  
  funN <- function(v){
    p <- v/sum(v)
    N <- length(p[p>tol])
    return(N)
  }
  N <- unlist(sapply(commt, funN))
  U <- Q/Sim
  
  
  red <- cbind.data.frame(N=N, D=Sim, Q=Q, U=U)
  rownames(red) <- rownames(comm)
  
  res <- list()
  res$Kbar <- Kbar
  res$V <- V
  res$red <- red
  return(res)
  
}







































