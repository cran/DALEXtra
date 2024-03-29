#' Wrapper for Python Scikit-Learn Models
#'
#' scikit-learn models may be loaded into R environment like any other Python object. This function helps to inspect performance of Python model
#' and compare it with other models, using R tools like DALEX. This function creates an object that is easily accessible R version of scikit-learn model
#' exported from Python via pickle file.
#'
#'
#' @param path a path to the pickle file. Can be used without other arguments if you are sure that active Python version match pickle version.
#' @param yml a path to the yml file. Conda virtual env will be recreated from this file. If OS is Windows conda has to be added to the PATH first
#' @param condaenv If yml param is provided, a path to the main conda folder. If yml is null, a name of existing conda environment.
#' @param env A path to python virtual environment.
#' @inheritParams DALEX::explain
#'
#'
#' @author Szymon Maksymiuk
#'
#'
#' @return An object of the class 'explainer'. It has additional field param_set when user can check parameters of scikit-learn model
#'
#' \bold{Example of Python code}\cr
#'
#' from pandas import DataFrame, read_csv \cr
#' import pandas as pd\cr
#' import pickle\cr
#' import sklearn.ensemble\cr
#' model = sklearn.ensemble.GradientBoostingClassifier() \cr
#' model = model.fit(titanic_train_X, titanic_train_Y)\cr
#' pickle.dump(model, open("gbm.pkl", "wb"), protocol = 2)\cr
#' \cr
#' \cr
#' In order to export environment into .yml, activating virtual env via \code{activate name_of_the_env} and execution of the following shell command is necessary \cr
#' \code{conda env export > environment.yml}\cr
#' \cr
#'
#' \bold{Errors use case}\cr
#' Here is shortened version of solution for specific errors \cr
#' \cr
#' \bold{There already exists environment with a name specified by given .yml file}\cr
#' If you provide .yml file that in its header contatins name exact to name of environment that already exists, existing will be set active without changing it. \cr
#' You have two ways of solving that issue. Both connected with anaconda prompt. First is removing conda env with command: \cr
#' \code{conda env remove --name myenv}\cr
#' And execute function once again. Second is updating env via: \cr
#' \code{conda env create -f environment.yml}\cr
#' \cr
#' \bold{Conda cannot find specified packages at channels you have provided.}\cr
#' That error may be casued by a lot of things. One of those is that specified version is too old to be avaialble from offcial conda repo.
#' Edit Your .yml file and add link to proper repository at channels section.\cr
#' \cr
#' Issue may be also connected with the platform. If model was created on the platform with different OS yo may need to remove specific version from .yml file.\cr
#' \code{- numpy=1.16.4=py36h19fb1c0_0}\cr
#' \code{- numpy-base=1.16.4=py36hc3f5095_0}\cr
#' In the example above You have to remove \code{=py36h19fb1c0_0} and \code{=py36hc3f5095_0} \cr
#' If some packages are not availbe for anaconda at all, use pip statement\cr
#' \cr
#' If .yml file seems not to work, virtual env can be created manually using anaconda promt. \cr
#' \code{conda create -n name_of_env python=3.4} \cr
#' \code{conda install -n name_of_env name_of_package=0.20} \cr
#'
#'
#' @import DALEX
#' @importFrom utils head
#'
#' @examples
#' \dontrun{
#' 
#'  if (Sys.info()["sysname"] != "Darwin") {
#'    # Explainer build (Keep in mind that 18th column is target)
#'    titanic_test <- read.csv(system.file("extdata", "titanic_test.csv", package = "DALEXtra"))
#'    # Keep in mind that when pickle is being built and loaded,
#'    # not only Python version but libraries versions has to match aswell
#'    explainer <- explain_scikitlearn(system.file("extdata", "scikitlearn.pkl", package = "DALEXtra"),
#'    yml = system.file("extdata", "testing_environment.yml", package = "DALEXtra"),
#'    data = titanic_test[,1:17], y = titanic_test$survived)
#'    plot(model_performance(explainer))
#'
#'    # Predictions with newdata
#'    predict(explainer, titanic_test[1:10,1:17])
#'  }
#' }
#'
#' @rdname explain_scikitlearn
#' @export
#'
explain_scikitlearn <-
  function(path,
           yml = NULL,
           condaenv = NULL,
           env = NULL,
           data = NULL,
           y = NULL,
           weights = NULL,
           predict_function = NULL,
           predict_function_target_column = NULL,
           residual_function = NULL,
           ...,
           label = NULL,
           verbose = TRUE,
           precalculate = TRUE,
           colorize = !isTRUE(getOption('knitr.in.progress')),
           model_info = NULL,
           type = NULL) {
    prepeare_env(yml, condaenv, env)

    model <- dalex_load_object(path, "scikitlearn_model")
    # Check if model stores info about his parameters
    params_available <- try(model$get_params, silent = TRUE)

    if (all(class(params_available) != "try-error")) {
      # params are represented as one long string
      params <- model$get_params
      # taking first element since strsplit() returns list of vectors
      params <- strsplit(as.character(params), split = ",")[[1]]
      # replacing blanks and other signs that we don't need and are pasted with params names
      params <-
        gsub(
          params,
          pattern = "\n",
          replacement = "",
          fixed = TRUE
        )
      params <-
        gsub(
          params,
          pattern = " ",
          replacement = "",
          fixed = TRUE
        )
      # splitting after "=" mark and taking first element (head(n = 1L)) provides as with params names
      params <- lapply(strsplit(params, split = "="), head, n = 1L)
      # removing name of function from the first parameter
      params[[1]] <- strsplit(params[[1]], split = "\\(")[[1]][2]
      # setting freshly extracted parameters names as labels for list
      names(params) <- as.character(params)
      #extracting parameters value
      params <- lapply(params, function(x) {
        do.call("$", list(model, x))
      })
    } else{
      params <- "Params not available"
    }


    class(params) <- "scikitlearn_set"
    explainer <- explain(
                          model,
                          data = data,
                          y = y,
                          weights = weights,
                          predict_function = predict_function,
                          predict_function_target_column = predict_function_target_column,
                          residual_function = residual_function,
                          ...,
                          label = label,
                          verbose = verbose,
                          precalculate = precalculate,
                          colorize = colorize,
                          model_info = model_info,
                          type = type
    )
    explainer$param_set <- params
    explainer
  }
