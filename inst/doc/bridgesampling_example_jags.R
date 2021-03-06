## -----------------------------------------------------------------------------
library(bridgesampling)

### generate data ###
set.seed(12345)

mu <- 0
tau2 <- 0.5
sigma2 <- 1

n <- 20
theta <- rnorm(n, mu, sqrt(tau2))
y <- rnorm(n, theta, sqrt(sigma2))
  

## ----eval=FALSE---------------------------------------------------------------
#  ### set prior parameters ###
#  mu0 <- 0
#  tau20 <- 1
#  alpha <- 1
#  beta <- 1

## ---- eval=FALSE--------------------------------------------------------------
#  library(R2jags)
#  
#  ### functions to get posterior samples ###
#  
#  # H0: mu = 0
#  getSamplesModelH0 <- function(data, niter = 52000, nburnin = 2000, nchains = 3) {
#  
#    model <- "
#      model {
#        for (i in 1:n) {
#          theta[i] ~ dnorm(0, invTau2)
#            y[i] ~ dnorm(theta[i], 1/sigma2)
#        }
#        invTau2 ~ dgamma(alpha, beta)
#        tau2 <- 1/invTau2
#      }"
#  
#    s <- jags(data, parameters.to.save = c("theta", "invTau2"),
#              model.file = textConnection(model),
#              n.chains = nchains, n.iter = niter,
#              n.burnin = nburnin, n.thin = 1)
#  
#    return(s)
#  
#  }
#  
#  # H1: mu != 0
#  getSamplesModelH1 <- function(data, niter = 52000, nburnin = 2000,
#                                nchains = 3) {
#  
#    model <- "
#      model {
#        for (i in 1:n) {
#          theta[i] ~ dnorm(mu, invTau2)
#          y[i] ~ dnorm(theta[i], 1/sigma2)
#        }
#        mu ~ dnorm(mu0, 1/tau20)
#        invTau2 ~ dgamma(alpha, beta)
#        tau2 <- 1/invTau2
#      }"
#  
#    s <- jags(data, parameters.to.save = c("theta", "mu", "invTau2"),
#              model.file = textConnection(model),
#              n.chains = nchains, n.iter = niter,
#              n.burnin = nburnin, n.thin = 1)
#  
#    return(s)
#  
#  }
#  
#  ### get posterior samples ###
#  
#  # create data lists for JAGS
#  data_H0 <- list(y = y, n = length(y), alpha = alpha, beta = beta, sigma2 = sigma2)
#  data_H1 <- list(y = y, n = length(y), mu0 = mu0, tau20 = tau20, alpha = alpha,
#                  beta = beta, sigma2 = sigma2)
#  
#  # fit models
#  samples_H0 <- getSamplesModelH0(data_H0)
#  samples_H1 <- getSamplesModelH1(data_H1)
#  

## ----eval=FALSE---------------------------------------------------------------
#  ### functions for evaluating the unnormalized posteriors on log scale ###
#  
#  log_posterior_H0 <- function(samples.row, data) {
#  
#    mu <- 0
#    invTau2 <- samples.row[[ "invTau2" ]]
#    theta <- samples.row[ paste0("theta[", seq_along(data$y), "]") ]
#  
#    sum(dnorm(data$y, theta, data$sigma2, log = TRUE)) +
#      sum(dnorm(theta, mu, 1/sqrt(invTau2), log = TRUE)) +
#      dgamma(invTau2, data$alpha, data$beta, log = TRUE)
#  
#  }
#  
#  log_posterior_H1 <- function(samples.row, data) {
#  
#    mu <- samples.row[[ "mu" ]]
#    invTau2 <- samples.row[[ "invTau2" ]]
#    theta <- samples.row[ paste0("theta[", seq_along(data$y), "]") ]
#  
#    sum(dnorm(data$y, theta, data$sigma2, log = TRUE)) +
#      sum(dnorm(theta, mu, 1/sqrt(invTau2), log = TRUE)) +
#      dnorm(mu, data$mu0, sqrt(data$tau20), log = TRUE) +
#      dgamma(invTau2, data$alpha, data$beta, log = TRUE)
#  
#  }
#  

## ----eval=FALSE---------------------------------------------------------------
#  # specify parameter bounds H0
#  cn <- colnames(samples_H0$BUGSoutput$sims.matrix)
#  cn <- cn[cn != "deviance"]
#  lb_H0 <- rep(-Inf, length(cn))
#  ub_H0 <- rep(Inf, length(cn))
#  names(lb_H0) <- names(ub_H0) <- cn
#  lb_H0[[ "invTau2" ]] <- 0
#  
#  # specify parameter bounds H1
#  cn <- colnames(samples_H1$BUGSoutput$sims.matrix)
#  cn <- cn[cn != "deviance"]
#  lb_H1 <- rep(-Inf, length(cn))
#  ub_H1 <- rep(Inf, length(cn))
#  names(lb_H1) <- names(ub_H1) <- cn
#  lb_H1[[ "invTau2" ]] <- 0

## ---- echo=FALSE--------------------------------------------------------------
load(system.file("extdata/", "vignette_example_jags.RData",
                     package = "bridgesampling"))

## ----eval=FALSE---------------------------------------------------------------
#  # compute log marginal likelihood via bridge sampling for H0
#  H0.bridge <- bridge_sampler(samples = samples_H0, data = data_H0,
#                              log_posterior = log_posterior_H0, lb = lb_H0,
#                              ub = ub_H0, silent = TRUE)
#  
#  # compute log marginal likelihood via bridge sampling for H1
#  H1.bridge <- bridge_sampler(samples = samples_H1, data = data_H1,
#                              log_posterior = log_posterior_H1, lb = lb_H1,
#                              ub = ub_H1, silent = TRUE)

## -----------------------------------------------------------------------------
print(H0.bridge)
print(H1.bridge)

## ----eval=FALSE---------------------------------------------------------------
#  # compute percentage errors
#  H0.error <- error_measures(H0.bridge)$percentage
#  H1.error <- error_measures(H1.bridge)$percentage

## -----------------------------------------------------------------------------
print(H0.error)
print(H1.error)

## -----------------------------------------------------------------------------
# compute Bayes factor
BF01 <- bf(H0.bridge, H1.bridge)
print(BF01)

## -----------------------------------------------------------------------------
# compute posterior model probabilities (assuming equal prior model probabilities)
post1 <- post_prob(H0.bridge, H1.bridge)
print(post1)

## -----------------------------------------------------------------------------
# compute posterior model probabilities (using user-specified prior model probabilities)
post2 <- post_prob(H0.bridge, H1.bridge, prior_prob = c(.6, .4))
print(post2)

