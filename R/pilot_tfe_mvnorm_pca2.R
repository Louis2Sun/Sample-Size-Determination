#' @title Estimation from Pilot Data using PCA_2 and Mvnorm
#' @description  Use PCA and select the first two PCs to reduce the dimension, then use multivariate normal distribution as the generative model and train different models.
#' @param x_pilot input variables of pilot data
#' @param y_pilot labels of pilot data
#' @param n0_train the number of training data of class 0
#' @param n1_train the number of training data of class 1
#' @param n0_test the number of test data of class 0
#' @param n1_test the number of test data of class 1
#' @param method base classification method.
#' \itemize{
#' \item logistic: Logistic regression. \link{glm} function with family = 'binomial'
#' \item penlog: Penalized logistic regression with LASSO penalty. \code{\link[glmnet]{glmnet}} in \code{glmnet} package
#' \item svm: Support Vector Machines. \code{\link[e1071]{svm}} in \code{e1071} package
#' \item randomforest: Random Forest. \code{\link[randomForest]{randomForest}} in \code{randomForest} package
#' \item lda: Linear Discriminant Analysis. \code{\link[MASS]{lda}} in \code{MASS} package
#' \item slda: Sparse Linear Discriminant Analysis with LASSO penalty.
#' \item nb: Naive Bayes. \code{\link[e1071]{naiveBayes}} in \code{e1071} package
#' \item nnb: Nonparametric Naive Bayes. \code{\link[naivebayes]{naive_bayes}} in \code{naivebayes} package
#' \item ada: Ada-Boost. \code{\link[ada]{ada}} in \code{ada} package
#' \item xgboost: XGBboost. \code{\link[xgboost]{xgboost}} in \code{xgboost} package
#' \item tree: Classificatin Tree. \code{\link[tree]{tree}} in \code{tree} package
#' \item self: You can use your self-defined function. You need to pass your self-defined function via the "func" parameter.
#' }
#' @param func If you set "method" to "self", you have to pass your self-defined model function. This function should be able to take "x_train" and "y_train" as the first two inputs to train the model and then take "x_test" as the third input and return the predicted scores of x_test data. For example, \cr\cr
#' \code{library(e1071)\cr\cr
#' predict_model <- function(x_train, y_train, x_test){ \cr
#' data_trainxy<-data.frame(x_train,y_train=as.factor(y_train)) \cr
#' fit_svm<-svm(y_train~.,data=data_trainxy,probability=TRUE) \cr
#' pred_svm <- predict(fit_svm, x_test, probability=TRUE,decision.values = TRUE) \cr
#' p_svm=as.data.frame(attr(pred_svm, "probabilities"))$"1" \cr
#' return(p_svm) \cr
#' }\cr \cr
#' result = pilot_tfe_mvnorm_pca2(x_pilot,y_pilot,n0_train,n1_train,n0_test,n1_test,method=c("self","randomforest"),func=predict_model)}
#'
#'
#' @return the scores predicted by models
#' @export
#' @importFrom randomForest randomForest
#' @importFrom e1071 svm
#' @importFrom xgboost xgboost
#' @importFrom glmnet cv.glmnet
#' @importFrom MASS lda
#' @importFrom naivebayes naive_bayes
#' @importFrom ada ada
#' @importFrom tree tree
#'
#' @examples
#'
#' library(mvtnorm)
#' library(MASS)
#'
#' df = 10
#' rho=0.5
#' d=5
#' delta = rep(2,d)
#' H<-abs(outer(1:d,1:d,"-"))
#' covxx=rho^H
#'
#' n1_all <- n0_all <- 800
#' n1_p <- n0_p <- 15
#'
#'x0_all = rmvt(n = n0_all, sigma = covxx, delta = rep(0,d), df = df)
#'x1_all = rmvt(n = n1_all, sigma = covxx, delta = delta, df = df)
#'
#'x_data = rbind(x0_all,x1_all)
#'y_data = c(rep(0,n0_all),rep(1,n1_all))
#'
#'id0 <- which(y_data==0)
#'id1 <- which(y_data==1)
#'
#'id0_p <- sample(id0,n0_p)
#'id1_p <- sample(id1,n1_p)
#'id_p <- c(id0_p,id1_p)
#'
#'x_pilot <- as.matrix(x_data[id_p,])
#'y_pilot <- as.matrix(y_data[id_p])
#'
#'n1_train <- n0_train <- n_train <-60
#'n0_test <- n1_test <- 300
#'
#'result = pilot_tfe_mvnorm_pca2(x_pilot,y_pilot,n0_train,n1_train,n0_test,n1_test,method=c("svm","randomforest"))
#'
#'
#'
pilot_tfe_mvnorm_pca2 <- function(x_pilot,y_pilot,n0_train,n1_train,n0_test,n1_test,method=c("svm","randomforest"),func=NULL)
{
  library(MASS)

  id0_p = which(y_pilot==0)
  id1_p = which(y_pilot==1)

  n0_p = length(id0_p)
  n1_p = length(id1_p)


  ### pca
  x_pilot.pca = prcomp(x_pilot,center = FALSE,scale. = FALSE)
  x0_pc1 = x_pilot.pca$x[id0_p,1]
  x1_pc1 = x_pilot.pca$x[id1_p,1]

  x0_pc2 = x_pilot.pca$x[id0_p,2]
  x1_pc2 = x_pilot.pca$x[id1_p,2]

  pc_p1=x_pilot.pca$rotation[,1]
  pc_p2=x_pilot.pca$rotation[,2]

  ### estimate the paramters: mean, variance
  mu0_hat1 = mean(x0_pc1)
  mu1_hat1 = mean(x1_pc1)

  mu0_hat2 = mean(x0_pc2)
  mu1_hat2 = mean(x1_pc2)

  mu0_hat = c(mu0_hat1,mu0_hat2)
  mu1_hat = c(mu1_hat1,mu1_hat2)

  x0_pc = cbind(x0_pc1,x0_pc2)
  cov0 = cov(x0_pc)
  x1_pc = cbind(x1_pc1,x1_pc2)
  cov1 = cov(x1_pc)

  sigma_hat = ((n0_p-1)*cov0+(n1_p-1)*cov1)/(n0_p+n1_p-2)


  ### generate the samples based on the estimated distributions
  n_train=n0_train+n1_train
  n_test=n0_test+n1_test


  ### y
  train_y=c(rep(0,n0_train),rep(1,n1_train))
  y0index=which(train_y==0)
  y1index=which(train_y==1)


  ### train
  train_x0=t(mvrnorm(n0_train, mu0_hat, sigma_hat))
  train_x1=t(mvrnorm(n1_train, mu1_hat, sigma_hat))
  trx=matrix(t(cbind(train_x0,train_x1)),n_train,2)
  train_x=as.data.frame(trx)

  ### test
  test_x0=t(mvrnorm(n0_test, mu0_hat, sigma_hat))
  test_x1=t(mvrnorm(n1_test, mu1_hat, sigma_hat))
  tex=matrix(t(cbind(test_x0,test_x1)),n_test,2)
  test_x=as.data.frame(tex)

  data_trainxy<-data.frame(train_x,train_y)

  methods_all = c("logistic", "penlog", "svm", "randomforest", "lda", "slda", "nb", "nnb", "ada", "tree","xgboost","self")

  p_results = numeric()
  # print(method)
  for (i in 1:length(method)){
    # print(method[i])
    if(!method[i] %in% methods_all){
      stop('method \'',method[i], '\' cannot be found')
    }

    ###LR
    if(method[i] == "logistic"){
      fit_LR<-suppressWarnings(glm(train_y~.,family = "binomial",data=data_trainxy, maxit=100))
      prep_LR<-predict(fit_LR,test_x)
      p_LR<-1/(1+exp(-prep_LR))
      p_results=rbind(p_results,p_LR)
    }

    ###xgboost
    if(method[i] == "xgboost"){
      new_trainx<-as.matrix(train_x)
      dx_trainy<-xgb.DMatrix(data = new_trainx, label = train_y)
      fit_xgb <- xgboost(data=dx_trainy, nthread=3,nrounds=100,objective = "binary:logistic", verbose = 0)
      p_xgb<-predict(fit_xgb,as.matrix(test_x))
      p_results=rbind(p_results,p_xgb)
    }

    ###SVM
    if(method[i] == "svm"){
      data_trainxy<-data.frame(train_x,train_y=as.factor(train_y))
      fit_svm<-svm(train_y~.,data=data_trainxy,probability=TRUE)
      pred_svm <- predict(fit_svm, test_x, probability=TRUE,decision.values = TRUE)
      p_svm=as.data.frame(attr(pred_svm, "probabilities"))$"1"
      p_results=rbind(p_results,p_svm)
    }

    ###RF
    if(method[i] == "randomforest"){
      data_trainxy<-data.frame(train_x,train_y=as.factor(train_y))
      fit_RF<-randomForest(train_y~.,data = data_trainxy,importance=TRUE)
      p_RF=predict(fit_RF,test_x,type = "prob")[, 2]
      p_results=rbind(p_results,p_RF)
    }

    ###Penalized logistic regression with LASSO penalty
    if(method[i] == "penlog"){
      fit_penlog = cv.glmnet(as.matrix(train_x), train_y, family = "binomial")
      p_penlog = t(predict(fit_penlog$glmnet.fit, newx = as.matrix(test_x), type = "response", s = fit_penlog$lambda.min))
      rownames(p_penlog)="p_penlog"
      p_results=rbind(p_results,p_penlog)
    }

    ###Linear Discriminant Analysis
    if(method[i] == "lda"){
      fit_lda = lda(as.matrix(train_x), train_y)
      p_lda = predict(fit_lda, as.matrix(test_x))$posterior[, 2]
      p_results=rbind(p_results,p_lda)
    }

    ###Sparse Linear Discriminant Analysis with LASSO penalty
    if(method[i] == "slda"){
      n1 = sum(train_y==1)
      n0 = sum(train_y==0)
      n = n1 + n0
      y_lda = train_y
      y_lda[train_y == 0] = -n/n0
      y_lda[train_y == 1] = n/n1
      fit_slda = cv.glmnet(as.matrix(train_x), y_lda)
      score_slda = t(predict(fit_slda$glmnet.fit, newx = as.matrix(test_x), type = "link", s = fit_slda$lambda.min))
      p_slda = 1/(1+exp(-score_slda))
      rownames(p_slda)="p_slda"
      p_results=rbind(p_results,p_slda)
    }

    ###Naive Bayes
    if(method[i] == "nb"){
      train_data_nb = data.frame(train_x, y = train_y)
      fit_nb <- naive_bayes(as.factor(y) ~ ., data = train_data_nb, usekernel = FALSE)
      p_nb = predict(fit_nb, data.frame(test_x), type = "prob")[,2]
      p_results=rbind(p_results,p_nb)
    }

    ###Nonparametric Naive Bayes
    if(method[i] == "nnb"){
      train_data_nnb = data.frame(train_x, y = train_y)
      fit_nnb <- naive_bayes(as.factor(y) ~ ., data = train_data_nnb, usekernel = TRUE)
      p_nnb = predict(fit_nnb, data.frame(test_x), type = "prob")[,2]
      p_results=rbind(p_results,p_nnb)
    }

    ###Ada-Boost
    if(method[i] == "ada"){
      train_data_ada = data.frame(train_x, y = train_y)
      fit_ada = ada(y ~ ., data = train_data_ada)
      p_ada = predict(fit_ada, data.frame(test_x), type = "probs")[, 2]
      p_results=rbind(p_results,p_ada)
    }

    ###Classification
    if(method[i] == "tree"){
      # train_y = as.factor(train_y)
      train_data_tree = data.frame(train_x, y = train_y)
      fit_tree = tree(y~ ., data = train_data_tree)
      p_tree = predict(fit_tree, newdata = data.frame(test_x), type = 'vector')
      p_results=rbind(p_results,p_tree)
    }

    ###Self-defined
    if(method[i] == "self"){
      p_self = func(train_x, train_y, test_x)
      p_results=rbind(p_results,p_self)
    }

  }

  return(p_results)

}
