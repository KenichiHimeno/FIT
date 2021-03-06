% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/FIT.R
\docType{package}
\name{FIT}
\alias{FIT}
\alias{FIT-package}
\title{FIT: a statistical modeling tool for transcriptome dynamics under fluctuating field conditions}
\description{
Provides functionality for constructing statistical models of transcriptomic dynamics in field 
conditions. It further offers the function to predict expression of a gene given the attributes 
of samples and meteorological data.
}
\section{Overview}{

The \pkg{FIT} package is an \code{R} implementation
of a class of transcriptomic models that
relates gene expressions of plants and weather conditions to which
the plants are exposed.
(The reader is referred to [Nagano et al.] for the detail of
the class of models concerned.)

By providing
(a) gene expression profiles of plants brought up in a field condition,
and (b) the relevant weather history (temperature etc.) of the said field,
the user of the package is able to
(1) construct optimized models (one for each gene) for their expressions,
and
(2) use them to predict the expressions for another weather history
(possibly in a different field).

Below, we briefly explain
the construction of the optimized models (``training phase'')
and the way to use them to make predictions (``prediction phase'').

\subsection{Model training phase}{

The model of [Nagano et al.] belongs to the class of statistical models
called ``linear models''
and are specified by a set of ``parameters'' and
``(linear regression) coefficients''.
The former are used to convert weather conditions to
the ``input variables'' for a regression, and the latter are then
multiplied to the input variables to form the expectation values
for the gene expressions.
The reader is referred to the original article [Nagano et al.]
for the formulas for the input variables.
(See also [Iwayama] for a review.)

The training phase consists of three stages:
\enumerate{
\item \code{Init}: fixes the initial model parameters
\item \code{Optim}: optimizes the model parameters
\item \code{Fit}: fixes the linear regression coefficients
}
The user can configure the training phase
through a custom data structure (``recipe''),
which can be constructed by using the utility function
\code{FIT::make.recipe()}.

The role of the first stage \code{Init} is to fix the initial values
for the model parameters from which the parameter optimization is performed.
At the moment two methods, \code{'manual'} and \code{'gridsearch'},
are implemented.
With the \code{'manual'} method the user can simply specify the set of
initial values that he thinks is promising.
For the \code{'gridsearch'} method the user discretizes
the parameter space to a grid by providing
a finite number of candidate values for each parameter.
\pkg{FIT} then performs a search over the grid
for the ``best'' combinations of the initial parameters.
% In both cases relevant data are passed through \code{init.data}.

The second stage \code{Optim} is the main step of the model training,
and \pkg{FIT} tries to gradually improve the model parameters
using the Nelder-Mead method.

This stage could be run one or more times where each can be run
using the method \code{'none'}, \code{'lm'} or \code{'lasso'}.
The \code{'none'} method passes the given parameter as-is
to the next method in the \code{Optim} pipeline or to the next stage \code{Fit}.
(Basically, the method is there so that the user can skip the entire
\code{Optim} stage, but the method could be used for slightly warming-up the CPU as well.)

The \code{'lm'} method uses the a simple (weighted) linear regression to
guide the parameter optimization. That is, \pkg{FIT}
first computes the ``input variables'' from the current parameters and
associated weather data, and then finds the set of linear coefficients
that best explains the ``output variables'' (gene expressions).
Finally, the quadratic residual is used as the measure for the
error and is fed back to the Nelder-Mead method.

The \code{'lasso'} method is similar to the \code{'lm'} method
but uses the (weighted) Lasso regression
(``linear'' regression with an L1-regularization for the regression coefficients)
instead of the simple linear regression.
\pkg{FIT} uses the \pkg{glmnet} package to perform
the Lasso regression and the strength of the L1-regularization
is fixed via a cross validation. (See \code{cv.glmnet()} from the \pkg{glmnet}
package.
The Lasso regression is said to suppress irrelevant input variables automatically
and tends to create models with better prediction ability.
On the other hand, \code{'lasso'} runs considerably slower than \code{'lm'}.

For example, passing a vector \code{c('lm', 'lasso')} to the
argument \code{optim} (of \code{make.recipe()}) creates a recipe
that instructs the \code{Optim} stage to
(1) first optimize using the \code{'lm'} method,
(2) and then fine tunes the parameters using the \code{'lasso'} method.

After fixing the model parameters in the \code{Optim} stage,
the \code{Fit} stage can be used to fix the linear coefficients
of the models.
Here, either \code{'fit.lm'} or \code{'fit.lasso'} can be used
to find the ``best'' coefficients, the main difference being that
the coefficients are penalized by an L1-norm for the latter.
Note that it is perfectly okay to use \code{'fit.lasso'} for
the parameters optimized using \code{'lm'}.

In order to prepare for the possibly huge variations
of expression data as measured by RNA-seq,
\pkg{FIT} provides a way to weight regression penalties from each sample
with different weights as in
\code{sum_{s in samples} (weight_s) (error_s)^2}.

} % subsection model training

\subsection{Prediction phase}{
For each gene, the trained model of the previous subsection
can be thought of as a black box that maps
the field conditions (weather data),
to which a plant containing the gene is exposed,
to its expected expression.
\pkg{FIT} provides a simple function
\code{FIT::predict()} that does just this.

\code{FIT::predict()} takes as its argument
a list of pretrained models
as well as actual/hypothetical plant sample attributes and weather data,
and returns the predicted values of gene expressions.

When there is a set of actually measured expressions,
an associated function \code{FIT::prediction.errors()})
can be used to check the validity of the predictions made by
the models.
} % subsection prediction phase
}

\section{Namespece contamination}{

The \pkg{FIT} package exports fairly ubiquitous names
auch as \code{optim}, \code{predict} etc.\ as its API.
Users, therefore, are advised to load \pkg{FIT}
via \code{requireNamespace('FIT')} and use its API function with
a namaspace qualifier (e.g.~\code{FIT::optim()})
rather than loading \emph{and} attaching it via \code{library('FIT')}.
}

\section{Sample training and prediction data}{

XXX See \code{extdata}.
}

\section{Basic usage}{

See vignettes for examples of actual scripts that use \pkg{FIT}.
}
\examples{
\dontrun{
# The following snippet shows the structure of a typical
# driver script of the FIT package.
# See vignettes for examples of actual scripts that use FIT.

##############
## training ##
##############
## discretized parameter space (for 'gridsearch')
grid.coords <- list(
  clock.phase = seq(0, 23*60, 1*60),
  # :
  gate.radiation.amplitude = c(-5, 5)
)
}
\dontshow{
grid.coords <- list(
  env.temperature.threshold = c(10, 30),
  env.temperature.amplitude = c(-100/30, 100/30),
  env.radiation.threshold = c(1, 40),
  env.radiation.amplitude = c(-100/80, 100/80),  
  env.temperature.period = c(1, 1440),
  env.radiation.period = c(1, 1440),
  gate.temperature.phase = seq(0, 23*60, 8*60),
  gate.radiation.phase = seq(0, 23*60, 8*60),
  gate.temperature.threshold = cos(pi*seq(8,24,8)/24),
  gate.radiation.threshold = cos(pi*seq(8,24,8)/24),
  gate.temperature.amplitude = c(-5, 5),
  gate.radiation.amplitude = c(-5, 5)
)
}

## create a training recipe
recipe <- FIT::make.recipe(c('temperature', 'radiation'),
                           init  = 'gridsearch',
                           init.data = grid.coords,
                           optim = c('lm'),
                           fit   = 'fit.lasso',
                           time.step = 10, 
                           opts =
                             list(lm    = list(maxit = 900),
                             lasso = list(maxit = 1000))
                           )

## names of genes to construct models
genes <- c('Os12g0189300', 'Os02g0724000')

\dontshow{
training.attribute   <- FIT::load.attribute(
                       system.file('extdata', 'train.attribute', package='FIT')
                     )
training.weather     <- FIT::load.weather(
                       system.file('extdata', 'train.weather', package='FIT'),
                       'weather', 
                       c('temperature', 'radiation')
                     )
training.expression  <- FIT::load.expression(
                       system.file('extdata', 'train.expression', package='FIT'),
                       'ex',
                       genes
                     )
training.attribute$data <- training.attribute$data[1:50,]
training.expression$rawdata <- training.expression$rawdata[1:50,]
}

\dontrun{
## load training data
training.attribute  <- FIT::load.attribute('attribute.2008.txt')
training.weather    <- FIT::load.weather('weather.2008.dat', 'weather')
training.expression <- FIT::load.expression('expression.2008.dat', 'ex', genes)
}

## models will be a list of trained models (length: ngenes)
models <- FIT::train(training.expression,
                     training.attribute,
                     training.weather,
                     recipe)

################
## prediction ##
################

\dontrun{
## load validation data
prediction.attribute  <- FIT::load.attribute('attribute.2009.txt');
prediction.weather    <- FIT::load.weather('weather.2009.dat', 'weather')
prediction.expression <- FIT::load.expression('expression.2009.dat', 'ex', genes)
}

\dontshow{
prediction.attribute   <- FIT::load.attribute(
                       system.file('extdata', 'prediction.attribute', package='FIT')
                     )
prediction.weather     <- FIT::load.weather(
                       system.file('extdata', 'prediction.weather', package='FIT'),
                       'weather', 
                       c('temperature', 'radiation')
                     )
}

## predict
prediction.result <- FIT::predict(models[[1]],
                                 prediction.attribute,
                                 prediction.weather)

}
\references{
[Nagano et al.] A.J.~Nagano, et al.
``Deciphering and prediction of transcriptome dynamics under fluctuating field conditions,''
Cell~151, 6, 1358--69 (2012)

[Iwayama] K.~Iwayama, et al. 
``FIT: statistical modeling tool for transcriptome dynamics under fluctuating field conditions,''
(in preparation)
}

