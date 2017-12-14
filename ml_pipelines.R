
library(sparklyr)

sc <- spark_connect(master = "local")

spark_mtcars <- sdf_copy_to(sc, mtcars)

my_pipeline <- ml_pipeline(
  ft_binarizer(sc, "mpg", "guzzler", 25),
  ft_r_formula(sc, guzzler ~ am + cyl),
  ml_logistic_regression(sc)
)

model <- ml_fit(my_pipeline, spark_mtcars)

ml_save(model, "new_model", overwrite = TRUE)

list.files("new_model/stages")
