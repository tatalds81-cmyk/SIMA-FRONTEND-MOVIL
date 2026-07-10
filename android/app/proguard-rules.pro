# TensorFlow Lite GPU delegate is optional for the current CPU-only facial flow.
# R8 can see references from the dependency even when the app does not package GPU classes.
-dontwarn org.tensorflow.lite.gpu.**
