% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/funnel_measure.R
\name{funnel_measure}
\alias{funnel_measure}
\title{Caluculate difference in performance in models across different categories}
\usage{
funnel_measure(
  champion,
  challengers,
  measure_function = NULL,
  nbins = 5,
  partition_data = champion$data,
  cutoff = 0.01,
  cutoff_name = "Other",
  factor_conversion_threshold = 7,
  show_info = TRUE,
  categories = NULL
)
}
\arguments{
\item{champion}{- explainer of champion model.}

\item{challengers}{- explainer of challenger model or list of explainers.}

\item{measure_function}{- measure function that calculates performance of model based on true observation and prediction.
Order of parameters is important and should be (y, y_hat). The measure calculated by the function
should have the property that lower score value indicates better model. If NULL, RMSE will be used for regression,
one minus auc for classification and crossentropy for multiclass classification.}

\item{nbins}{- Number of quantiles (partition points) for numeric columns. In case when more than one quantile have the same value, there will be less partition points.}

\item{partition_data}{- Data by which test dataset will be partitioned for computation. Can be either data.frame or character vector.
When second is passed, it has to indicate names of columns that will be extracted from test data.
By default full test data. If data.frame, number of rows has to be equal to number of rows in test data.}

\item{cutoff}{- Threshold for categorical data. Entries less frequent than specified value will be merged into one category.}

\item{cutoff_name}{- Name for new category that arised after merging entries less frequent than \code{cutoff}}

\item{factor_conversion_threshold}{- Numeric columns with lower number of unique values than value of this parameter will be treated as factors}

\item{show_info}{- Logical value indicating if progress bar should be shown.}

\item{categories}{- a named list of variable names that will be plotted in a different colour. By default it is partitioned on Explanatory, External and Target.}
}
\value{
An object of the class \code{funnel_measure}

It is a named list containing following fields:
\itemize{
\item \code{data} data.frame that consists of columns:
   \itemize{
   \item \code{Variable} Variable according to which partitions were made
   \item \code{Measure} Difference in measures. Positive value indicates that champion was better, while negative that challenger.
   \item \code{Label} String that defines subset of \code{Variable} values (partition rule).
   \item \code{Challenger} Label of challenger explainer that was used in \code{Measure}
   \item \code{Category} a category of the variable passed to function
   }
\item \code{models_info} data.frame containing information about models used in analysis
}
}
\description{
Function \code{funnel_measure} allows users to compare two models based on their explainers. It partitions dataset on which models were built
and creates categories according to quantiles of columns in \code{parition data}. \code{nbins} parameter determines number of quantiles.
For each category difference in provided measure is being calculated. Positive value of that difference means that Champion model
has better performance in specified category, while negative value means that one of the Challengers was better. Function allows
to compare multiple Challengers at once.
}
\examples{
\donttest{
library("mlr")
library("DALEXtra")
task <- mlr::makeRegrTask(
  id = "R",
  data = apartments,
  target = "m2.price"
)
learner_lm <- mlr::makeLearner(
  "regr.lm"
)
model_lm <- mlr::train(learner_lm, task)
explainer_lm <- explain_mlr(model_lm, apartmentsTest, apartmentsTest$m2.price, label = "LM")

learner_rf <- mlr::makeLearner(
  "regr.ranger"
)
model_rf <- mlr::train(learner_rf, task)
explainer_rf <- explain_mlr(model_rf, apartmentsTest, apartmentsTest$m2.price, label = "RF")

learner_gbm <- mlr::makeLearner(
  "regr.gbm"
)
model_gbm <- mlr::train(learner_gbm, task)
explainer_gbm <- explain_mlr(model_gbm, apartmentsTest, apartmentsTest$m2.price, label = "GBM")


plot_data <- funnel_measure(explainer_lm, list(explainer_rf, explainer_gbm),
                            nbins = 5, measure_function = DALEX::loss_root_mean_square)
plot(plot_data)
}
}
