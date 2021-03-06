% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/calculate_AUC_base.R
\name{calculate_AUC_base}
\alias{calculate_AUC_base}
\title{calculate_AUC_base}
\usage{
calculate_AUC_base(
  n01_all = c(800, 800),
  n01_p = c(15, 15),
  n_train_sets = c(c(15, 15), c(30, 30), c(60, 60), c(120, 120), c(150, 150)),
  n01_test = c(300, 300),
  seed = 1,
  method = "pca2_mvnorm",
  model = c("svm", "randomforest"),
  func = NULL,
  data_generation = list(dist = "t-distribution", sigma = list(class_0 = diag(5),
    class_1 = diag(5)), df = c(10, 10), delta = c(rep(0, 5), rep(2, 5))),
  data_input = NULL
)
}
\arguments{
\item{n01_all}{size of all data labeled as class 0/1. For example, n01_all=c(800,800) represents that the size of all data labeled as class 0 is 800 and the size of all data labeled as class 1 is also 800.}

\item{n01_p}{size of pilot data labeled as class 0/1. For example, n01_p=c(15,15) represents that the size of pilot data labeled as class 0 is 15 and the size of pilot data labeled as class 1 is also 15.}

\item{n_train_sets}{size sets of training data labeled as class 0/1. For example, n_train_sets=c(c(30,30),c(90,90),c(150,150)) represents that we try 3 different sets of training data and the training size of the first set is c(30,30).}

\item{n01_test}{number of test data labeled as class 0/1. size of all data labeled as class 0/1. For example, n01_test=c(300,300) represents that the size of test data labeled as class 0 is 300 and the size of test data labeled as class 1 is also 300.}

\item{method}{Choose the method you want to use: "pca2_mvnorm" and "gaussian_copula".
The default value is "pca2_mvnorm".}

\item{model}{base classification model.
\itemize{
\item logistic: Logistic regression. \link{glm} function with family = 'binomial'
\item penlog: Penalized logistic regression with LASSO penalty. \code{\link[glmnet]{glmnet}} in \code{glmnet} package
\item svm: Support Vector Machines. \code{\link[e1071]{svm}} in \code{e1071} package
\item randomforest: Random Forest. \code{\link[randomForest]{randomForest}} in \code{randomForest} package
\item lda: Linear Discriminant Analysis. \code{\link[MASS]{lda}} in \code{MASS} package
\item slda: Sparse Linear Discriminant Analysis with LASSO penalty.
\item nb: Naive Bayes. \code{\link[e1071]{naiveBayes}} in \code{e1071} package
\item nnb: Nonparametric Naive Bayes. \code{\link[naivebayes]{naive_bayes}} in \code{naivebayes} package
\item ada: Ada-Boost. \code{\link[ada]{ada}} in \code{ada} package
\item xgboost: XGBboost. \code{\link[xgboost]{xgboost}} in \code{xgboost} package
\item tree: Classificatin Tree. \code{\link[tree]{tree}} in \code{tree} package
\item self: You can use your self-defined function. You need to pass your self-defined function via the "func" parameter.
}}

\item{func}{If you set "model" to "self", you have to pass your self-defined model function. This function should be able to take "x_train" and "y_train" as the first two inputs to train the model and then take "x_test" as the third input and return the predicted scores of x_test data. For example, \cr\cr
\code{library(e1071)\cr\cr
predict_model <- function(x_train, y_train, x_test){ \cr
data_trainxy<-data.frame(x_train,y_train=as.factor(y_train)) \cr
fit_svm<-svm(y_train~.,data=data_trainxy,probability=TRUE) \cr
pred_svm <- predict(fit_svm, x_test, probability=TRUE,decision.values = TRUE) \cr
p_svm=as.data.frame(attr(pred_svm, "probabilities"))$"1" \cr
return(p_svm) \cr
}\cr \cr
AUC = calculate_AUC_base(n01_all= c(800,800), n01_p=c(15,15), n01_test=c(300,300), n_train_sets = c(c(15,15),c(30,30),c(60,60),c(120,120),c(150,150)), seed=1, model=c("self","randomforest"),func=predict_model)}}

\item{data_generation}{a parameter list that you can tell the function about the distribution and parameters you want to use to generate the data.
\itemize{
\item "gaussian" represent multivariate gaussian distribution. see \code{\link[MASS]{mvrnorm}} in \code{MASS} package. For example, data_generation=list(dist="gaussian",sigma=list(class_0=diag(5),class_1=diag(5)),mu=c(rep(0,5),rep(2,5)))
\item "t-distribution" represent multivariate t distribution. see \code{\link[mvtnorm]{rmvt}} in \code{mvtnorm} package. For example, data_generation=list(dist="t-distribution",sigma=list(class_0=diag(5),class_1=diag(5)),df=c(10,10),delta=c(rep(0,5),rep(2,5))).
}}

\item{data_input}{Its default value is NULL and the function will use the "data_generation" parameter to generate the data. If "data_input" is not NULL, the function will ignore the "data_generation" parameter and "n01_all" parameter, and use the "data_input" as the data.
Your "data_input" should be a list with "x_data" matrix and "y_data" matrix. For example, \cr\cr
\code{

yeast_data <- read.table("./yeast.data") \cr}
###\link{https://archive.ics.uci.edu/ml/datasets/Diabetic+Retinopathy+Debrecen+Data+Set}\cr\cr
\code{
x_data = yeast_data[,c(2:5,8:9)]\cr
y_label = yeast_data[,10]\cr
id0 = which(y_label=="CYT" | y_label=="MIT")\cr
y_data = rep(1,length(y_label))\cr
y_data[id0] = 0\cr
\cr
data = list(x_data=x_data, y_data=y_data)\cr\cr

AUC = calculate_AUC_base(n01_p=c(15,15), n_train_sets = c(c(15,15),c(30,30),c(60,60),c(120,120),c(150,150)), n01_test=c(300,300), seed=1, method="pca2_mvnorm", model=c("svm","randomforest"), data_input=data)\cr
}}

\item{num_of_seeds}{number of seeds you want to use to run simulations.}
}
\value{
Return the AUCs you want to calculate
}
\description{
the base function of calculate_AUCs: build the model and calculate the AUCs
}
\examples{
AUC = calculate_AUC_base(n01_all = c(800, 800), n01_p = c(15, 15), n01_test = c(300, 
    300), n_train_sets = c(c(15, 15), c(30, 30), c(60, 60), c(120, 120), c(150, 150)), 
    seed = 1, model = c("svm", "randomforest"))
}
