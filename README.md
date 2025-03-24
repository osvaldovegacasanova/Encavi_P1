# 🧪 Análisis Factorial y Modelo Predictivo con Random Forest — ENCAVI Chile

Este repositorio contiene un script en R diseñado para realizar un **análisis factorial exploratorio** sobre la base de datos de la encuesta ENCAVI (Chile), seguido de la construcción de modelos de clasificación con **Random Forest** para predecir enfermedades respiratorias.

---

## 📁 Archivos

- `AF_encavi.R`: script completo y documentado que realiza el flujo de análisis.
- `encavi.csv`: base de datos con variables relacionadas a salud y calidad de vida.

---

## 📊 Flujo del Script

1. **Carga de datos y librerías**
2. **Exploración preliminar** de variables
3. **Transformación de variables categóricas** (solo la variable `V1`, sexo)
4. **Eliminación de variables altamente correlacionadas o dependientes**
5. **Cálculo de matriz de correlación de Spearman**
6. **Análisis factorial exploratorio** con rotación Varimax
7. **Entrenamiento de dos modelos Random Forest**:
   - Uno usando todas las variables dummy
   - Otro usando solo las puntuaciones factoriales
8. **Balanceo de clases** con ROSE (Random Over-Sampling Examples)
9. **Evaluación comparativa** de ambos modelos con métricas como:
   - Accuracy
   - Sensibilidad
   - Especificidad
10. **Visualización final** de las métricas comparativas

---

## 📈 Requisitos

```r
install.packages(c("caret", "randomForest", "psych", "ROSE", "ggplot2", "corrplot", "funModeling", "reshape2", "vcd"))
```

---

## 📌 Notas importantes

- La única variable convertida a dummy es `V1` (sexo: Hombre/Mujer).
- Las variables dependientes como hipertensión, diabetes, etc., se excluyen para evitar sesgos en el análisis factorial.
- El análisis factorial se basa en una matriz de correlación de Spearman.
- Las clases se balancean antes de entrenar los modelos para evitar desbalance en la variable `res` (enfermedad respiratoria).

---

## 📤 Autor

Ejercicio desarrollado por Osvaldo Vega Casanova como parte de un análisis exploratorio con enfoque en ciencia de datos aplicada a salud pública.
