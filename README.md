sparklyr Pipeline
================

Install `sparklyr` from a branch
--------------------------------

Use the `feature/ml-pipeline` branch to access the new pipeline features

``` r
devtools::install_github("rstudio/sparklyr")
```

    ## Skipping install of 'sparklyr' from a github remote, the SHA1 (a16b0953) has not changed since last install.
    ##   Use `force = TRUE` to force installation

Open a local `sparklyr` connection
----------------------------------

``` r
library(sparklyr)
sc <- spark_connect(master = "local")
```


    ## * Using Spark: 2.1.0

Copy mtcars and split them for test and training
------------------------------------------------

``` r
spark_mtcars <- sdf_copy_to(sc, mtcars, overwrite = TRUE) %>%
 sdf_partition(training = 0.4, testing = 0.6)
```

Create the pipeline
-------------------

Create a new `ml_pipeline()` object, and pass each step as an argument. The result is a 3 stage pipeline.

``` r
my_pipeline <- ml_pipeline(sc) %>%
  ft_binarizer("mpg", "guzzler", 20) %>%
  ft_r_formula(guzzler ~ wt + cyl) %>%
  ml_logistic_regression()

my_pipeline
```

    ## Pipeline (Estimator) with 3 stages
    ## <pipeline_17945f407216> 
    ##   Stages 
    ##   |--1 Binarizer (Transformer)
    ##   |    <binarizer_179436bf21f6> 
    ##   |     (Parameters -- Column Names)
    ##   |      input_col: mpg
    ##   |      output_col: guzzler
    ##   |--2 RFormula (Estimator)
    ##   |    <r_formula_1794180aa2a> 
    ##   |     (Parameters -- Column Names)
    ##   |      features_col: features
    ##   |      label_col: label
    ##   |     (Parameters)
    ##   |      force_index_label: FALSE
    ##   |      formula: guzzler ~ wt + cyl
    ##   |--3 LogisticRegression (Estimator)
    ##   |    <logistic_regression_1794617a7030> 
    ##   |     (Parameters -- Column Names)
    ##   |      features_col: features
    ##   |      label_col: label
    ##   |      prediction_col: prediction
    ##   |      probability_col: probability
    ##   |      raw_prediction_col: rawPrediction
    ##   |     (Parameters)
    ##   |      aggregation_depth: 2
    ##   |      elastic_net_param: 0
    ##   |      family: auto
    ##   |      fit_intercept: TRUE
    ##   |      max_iter: 100
    ##   |      reg_param: 0
    ##   |      standardization: TRUE
    ##   |      threshold: 0.5
    ##   |      tol: 1e-06

Train the model
---------------

Use `ml_fit()` to train the model, and save the results to the `model` variable.

``` r
model <- ml_fit(my_pipeline, spark_mtcars$training)

model
```

    ## PipelineModel (Transformer) with 3 stages
    ## <pipeline_17945f407216> 
    ##   Stages 
    ##   |--1 Binarizer (Transformer)
    ##   |    <binarizer_179436bf21f6> 
    ##   |     (Parameters -- Column Names)
    ##   |      input_col: mpg
    ##   |      output_col: guzzler
    ##   |--2 RFormulaModel (Transformer)
    ##   |    <r_formula_1794180aa2a> 
    ##   |     (Parameters -- Column Names)
    ##   |      features_col: features
    ##   |      label_col: label
    ##   |     (Transformer Info)
    ##   |      formula:  chr "guzzler ~ wt + cyl" 
    ##   |--3 LogisticRegressionModel (Transformer)
    ##   |    <logistic_regression_1794617a7030> 
    ##   |     (Parameters -- Column Names)
    ##   |      features_col: features
    ##   |      label_col: label
    ##   |      prediction_col: prediction
    ##   |      probability_col: probability
    ##   |      raw_prediction_col: rawPrediction
    ##   |     (Transformer Info)
    ##   |      coefficient_matrix:  num [1, 1:2] -11.6 -14.3 
    ##   |      coefficients:  num [1:2] -11.6 -14.3 
    ##   |      intercept:  num 133 
    ##   |      intercept_vector:  num 133 
    ##   |      num_classes:  int 2 
    ##   |      num_features:  int 2 
    ##   |      threshold:  num 0.5

Evaluate the model
------------------

`ml_transform()` would be the equivalent of a `predict()` function. The command is basically saying take the `spark_mtcars$testing` dataset and "transform" it using this pipeline, which happens to have a modeling step at the end.

``` r
predictions <- ml_transform(x = model, 
                            dataset = spark_mtcars$testing)


dplyr::glimpse(predictions)
```

    ## Observations: 24
    ## Variables: 17
    ## $ mpg           <dbl> 10.4, 13.3, 14.3, 14.7, 15.0, 15.2, 15.2, 15.5, ...
    ## $ cyl           <dbl> 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 6, 6, 6, 8, 6, 6, ...
    ## $ disp          <dbl> 472.0, 350.0, 360.0, 440.0, 301.0, 275.8, 304.0,...
    ## $ hp            <dbl> 205, 245, 245, 230, 335, 180, 150, 150, 180, 180...
    ## $ drat          <dbl> 2.93, 3.73, 3.21, 3.23, 3.54, 3.07, 3.15, 2.76, ...
    ## $ wt            <dbl> 5.250, 3.840, 3.570, 5.345, 3.570, 3.780, 3.435,...
    ## $ qsec          <dbl> 17.98, 15.41, 15.84, 17.42, 14.60, 18.00, 17.30,...
    ## $ vs            <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, ...
    ## $ am            <dbl> 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, ...
    ## $ gear          <dbl> 3, 3, 3, 3, 5, 3, 3, 3, 3, 3, 4, 3, 4, 3, 5, 4, ...
    ## $ carb          <dbl> 4, 4, 4, 4, 8, 3, 2, 2, 3, 3, 4, 1, 4, 2, 6, 4, ...
    ## $ guzzler       <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, ...
    ## $ features      <list> [<5.25, 8.00>, <3.84, 8.00>, <3.57, 8.00>, <5.3...
    ## $ label         <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, ...
    ## $ rawPrediction <list> [<41.55991, -41.55991>, <25.20131, -25.20131>, ...
    ## $ probability   <list> [<1.000000e+00, 8.928093e-19>, <1.000000e+00, 1...
    ## $ prediction    <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 1, 1, ...

``` r
predictions %>%
  dplyr::group_by(guzzler, prediction) %>%
  dplyr::tally()
```

    ## # Source:   lazy query [?? x 3]
    ## # Database: spark_connection
    ## # Groups:   guzzler
    ##   guzzler prediction     n
    ##     <dbl>      <dbl> <dbl>
    ## 1       0          1     4
    ## 2       0          0    11
    ## 3       1          1     9

Save the model
--------------

The model can be saved to disk using `ml_save`.

``` r
ml_save(model, "new_model", overwrite = TRUE)
```

    ## NULL

The saved model retains the transformation stages

``` r
list.files("new_model")
```

    ## [1] "metadata" "stages"

``` r
spark_disconnect(sc)
```

Reload the model
----------------

We will use a new connection to confirm that the model can be reloaded

``` r
library(sparklyr)
sc <- spark_connect(master = "local")
```


    ## * Using Spark: 2.1.0

Use `ml_load()` to read the saved model

``` r
spark_mtcars <- sdf_copy_to(sc, mtcars, overwrite = TRUE) 

reload <- ml_load(sc, "new_model")

reload
```

    ## PipelineModel (Transformer) with 3 stages
    ## <pipeline_17945f407216> 
    ##   Stages 
    ##   |--1 Binarizer (Transformer)
    ##   |    <binarizer_179436bf21f6> 
    ##   |     (Parameters -- Column Names)
    ##   |      input_col: mpg
    ##   |      output_col: guzzler
    ##   |--2 RFormulaModel (Transformer)
    ##   |    <r_formula_1794180aa2a> 
    ##   |     (Parameters -- Column Names)
    ##   |      features_col: features
    ##   |      label_col: label
    ##   |--3 LogisticRegressionModel (Transformer)
    ##   |    <logistic_regression_1794617a7030> 
    ##   |     (Parameters -- Column Names)
    ##   |      features_col: features
    ##   |      label_col: label
    ##   |      prediction_col: prediction
    ##   |      probability_col: probability
    ##   |      raw_prediction_col: rawPrediction
    ##   |     (Transformer Info)
    ##   |      coefficient_matrix:  num [1, 1:2] -11.6 -14.3 
    ##   |      coefficients:  num [1:2] -11.6 -14.3 
    ##   |      intercept:  num 133 
    ##   |      intercept_vector:  num 133 
    ##   |      num_classes:  int 2 
    ##   |      num_features:  int 2 
    ##   |      threshold:  num 0.5

``` r
reload_predictions <- ml_transform(x = reload, 
                            dataset = spark_mtcars)

dplyr::glimpse(reload_predictions)
```

    ## Observations: 25
    ## Variables: 17
    ## $ mpg           <dbl> 21.0, 21.0, 22.8, 21.4, 18.7, 18.1, 14.3, 24.4, ...
    ## $ cyl           <dbl> 6, 6, 4, 6, 8, 6, 8, 4, 4, 6, 6, 8, 8, 8, 8, 8, ...
    ## $ disp          <dbl> 160.0, 160.0, 108.0, 258.0, 360.0, 225.0, 360.0,...
    ## $ hp            <dbl> 110, 110, 93, 110, 175, 105, 245, 62, 95, 123, 1...
    ## $ drat          <dbl> 3.90, 3.90, 3.85, 3.08, 3.15, 2.76, 3.21, 3.69, ...
    ## $ wt            <dbl> 2.620, 2.875, 2.320, 3.215, 3.440, 3.460, 3.570,...
    ## $ qsec          <dbl> 16.46, 17.02, 18.61, 19.44, 17.02, 20.22, 15.84,...
    ## $ vs            <dbl> 0, 0, 1, 1, 0, 1, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, ...
    ## $ am            <dbl> 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ...
    ## $ gear          <dbl> 4, 4, 4, 3, 3, 3, 3, 4, 4, 4, 4, 3, 3, 3, 3, 3, ...
    ## $ carb          <dbl> 4, 4, 1, 1, 2, 1, 4, 2, 2, 4, 4, 3, 3, 3, 4, 4, ...
    ## $ guzzler       <dbl> 1, 1, 1, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, ...
    ## $ features      <list> [<2.62, 6.00>, <2.875, 6.000>, <2.32, 4.00>, <3...
    ## $ label         <dbl> 1, 1, 1, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, ...
    ## $ rawPrediction <list> [<-17.46984, 17.46984>, <-14.51137, 14.51137>, ...
    ## $ probability   <list> [<2.587884e-08, 1.000000e+00>, <4.986459e-07, 9...
    ## $ prediction    <dbl> 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, ...

``` r
spark_disconnect(sc)
```
