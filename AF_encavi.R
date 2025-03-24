## ANÁLISIS FACTORIAL Y RANDOM FOREST SOBRE ENCAVI.CSV

# ============================
# 1. CARGA DE LIBRERÍAS
# ============================
library(readr)
library(ggplot2)
library(vcd)
library(caret)
library(funModeling)
library(dplyr)
library(corrplot)
library(psych)
library(randomForest)
library(ROSE)

# ============================
# 2. CARGA DE DATOS
# ============================
dag <- read.csv("encavi.csv")  # Asegúrate de que esté en el directorio de trabajo

# ============================
# 3. EXPLORACIÓN INICIAL
# ============================

# Nota: La única variable categórica que se transforma en dummy es V1,
# que originalmente contiene los valores "H" (hombre) y "M" (mujer).
head(dag)
names(dag)
dim(dag)
table(dag$res)  # distribución de la variable objetivo

# ============================
# 4. ANÁLISIS DE VARIABLES
# ============================
status <- df_status(dag, print_results = FALSE)
cat_vars <- filter(status, type %in% c("factor", "character")) %>% select(variable)

# ============================
# 5. TRANSFORMACIÓN: DUMMY VARIABLES
# ============================

# Nota: La única variable categórica que se transforma en dummy es V1,
# que originalmente contiene los valores "H" (hombre) y "M" (mujer).
dmy <- dummyVars(" ~ .", data = dag)
daf1 <- data.frame(predict(dmy, newdata = dag))

# ============================
# 6. LIMPIEZA DE VARIABLES
# ============================
borrar <- c("v1H", "hip", "dia", "car", "vas", "res")
borrar_enf_but_res <- c("v1H", "hip", "dia", "car", "vas")

daf2 <- daf1[, !(names(daf1) %in% borrar)]              # para análisis factorial
daf_res <- daf1[, !(names(daf1) %in% borrar_enf_but_res)]  # mantiene la variable 'res'

# ============================
# 7. ANÁLISIS FACTORIAL
# ============================
# (Usar solo variables numéricas y evitar dummies si es posible en otra versión)

mat_cor <- cor(daf2, method = "spearman") %>% round(2)
corrplot(mat_cor, type = "upper", order = "hclust", tl.col = "black", tl.srt = 45)

# Pruebas de factorizabilidad
bartlett_test <- cortest.bartlett(mat_cor)
kmo_result <- KMO(mat_cor)

print(bartlett_test$p.value)
print(kmo_result)

# Scree plot y análisis paralelo
scree(mat_cor)
fa.parallel(mat_cor, n.obs = nrow(dag), fa = "fa", fm = "minres")

# Modelo factorial (ajustar número de factores según scree/parallel)
modelo_varimax <- fa(mat_cor, nfactors = 11, rotate = "varimax", fa = "minres")
fa.diagram(modelo_varimax)
print(modelo_varimax$loadings, cut = 0)

# Calcular puntuaciones factoriales y añadir la variable objetivo
factor_scores <- factor.scores(daf2, modelo_varimax)
factor_df <- as.data.frame(factor_scores$scores)
factor_df$res <- dag$res  # agregar variable dependiente original

# ============================
# 8. RANDOM FOREST SIN ANÁLISIS FACTORIAL
# ============================
cat("\n\n================ RANDOM FOREST SIN ANÁLISIS FACTORIAL ================\n")

# Convertir res a factor con niveles consistentes
dag_res <- daf_res  # crear copia para no modificar original
dag_res$res <- factor(dag$res, levels = c("0", "1"))

# Balancear clases con ROSE
dag_bal <- ROSE(res ~ ., data = dag_res, seed = 123)$data
table(dag_bal$res)

# Dividir datos
set.seed(123)
train_index <- createDataPartition(dag_bal$res, p = 0.8, list = FALSE)
train_data <- dag_bal[train_index, ]
test_data <- dag_bal[-train_index, ]

# Modelo Random Forest
rf_model <- randomForest(res ~ ., data = train_data, ntree = 500, mtry = 3, importance = TRUE)

# Evaluación
importance(rf_model)
varImpPlot(rf_model)

predictions <- predict(rf_model, newdata = test_data, type = "class")
cm_sin <- confusionMatrix(predictions, test_data$res, positive = "1")
print(cm_sin)

# ============================
# 9. RANDOM FOREST CON PUNTUACIONES FACTORIALES
# ============================
cat("\n\n================ RANDOM FOREST CON ANÁLISIS FACTORIAL ================\n")

# Convertir 'res' a factor para ROSE
factor_df$res <- as.factor(factor_df$res)

# Balancear clases con ROSE sobre puntuaciones factoriales
factor_bal <- ROSE(res ~ ., data = factor_df, seed = 123)$data
table(factor_bal$res)

# División de datos
set.seed(123)
train_index_f <- createDataPartition(factor_bal$res, p = 0.8, list = FALSE)
train_factor <- factor_bal[train_index_f, ]
test_factor <- factor_bal[-train_index_f, ]

# Modelo con puntuaciones factoriales
rf_factor <- randomForest(res ~ ., data = train_factor, ntree = 500, mtry = 3, importance = TRUE)

# Evaluación
importance(rf_factor)
varImpPlot(rf_factor)

pred_factor <- predict(rf_factor, newdata = test_factor, type = "class")
cm_factor <- confusionMatrix(pred_factor, test_factor$res, positive = "1")
print(cm_factor)

# ============================
# 10. COMPARACIÓN DE MÉTRICAS
# ============================
cat("

================ COMPARACIÓN DE MÉTRICAS ================
")

cm_sin <- confusionMatrix(predictions, test_data$res, positive = "1")

# Extraer métricas clave de ambos modelos
metricas_comparacion <- data.frame(
  Modelo = c("Sin Análisis Factorial", "Con Análisis Factorial"),
  Accuracy = c(cm_sin$overall["Accuracy"], cm_factor$overall["Accuracy"]),
  Sensibilidad = c(cm_sin$byClass["Sensitivity"], cm_factor$byClass["Sensitivity"]),
  Especificidad = c(cm_sin$byClass["Specificity"], cm_factor$byClass["Specificity"])
)

print(metricas_comparacion)

# Visualización con ggplot2
library(reshape2)
metricas_melt <- melt(metricas_comparacion, id.vars = "Modelo")

ggplot(metricas_melt, aes(x = variable, y = value, fill = Modelo)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(title = "Comparación de Métricas entre Modelos",
       x = "Métrica",
       y = "Valor",
       fill = "Modelo") +
  theme_minimal()
