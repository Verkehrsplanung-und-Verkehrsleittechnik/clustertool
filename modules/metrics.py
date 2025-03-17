## @package metrics
#  @brief This module provides distance and similarity metrics for time-series clustering.
#
#  The `metrics` module includes functions for calculating various distance and similarity
#  measures between time-series data while handling missing values (NaNs). The following
#  metrics are implemented:
#
#  - **GEH statistic** (`geh`): Used to compare modeled and observed data.
#  - **SQV similarity** (`sqv_counts`): Measures the similarity of time-series based on a quadratic variation approach.
#  - **Euclidean distance** (`euclidean`): Computes the standard Euclidean distance while ignoring NaNs.
#
#  These functions are commonly used in clustering algorithms such as hierarchical clustering or k-means.
#
#  @author MaS, GPT
#  @date 2025
#
#  @note The `sqv_counts` function ensures symmetry in the similarity measure by using
#  the maximum of both values in the denominator.

import numpy as np


## @brief Computes the average GEH statistic between two time-series vectors while ignoring NaN values.
#
# The GEH (Geoffrey E. Havers) statistic is used to compare modeled and observed data,
# often in transportation modeling. It is defined as:
# \f$ GEH = \sqrt{\frac{2 (q_1 - q_2)^2}{q_1 + q_2 + \epsilon}} \f$
#
# @param vec_q1 First time-series vector.
# @param vec_q2 Second time-series vector.
# @param flag_mean If True, returns the mean GEH value; otherwise, returns the element-wise GEH values.
# @return The mean GEH value if `flag_mean=True`, else a numpy array of GEH values.
def geh(vec_q1, vec_q2, flag_mean: bool = True):
    mask = ~np.isnan(vec_q1) & ~np.isnan(vec_q2)  # Ignore NaN values
    if np.sum(mask) == 0:
        return np.nan  # No valid values to compare

    ## @var diff
    #  The difference between corresponding elements in vec_q1 and vec_q2.
    diff = vec_q1[mask] - vec_q2[mask]

    ## @var geh
    #  The computed GEH statistic for valid elements.
    geh = np.sqrt((2 * (diff ** 2)) / (vec_q1[mask] + vec_q2[mask] + 1e-308))

    return geh.mean() if flag_mean else geh


## @brief Computes the SQV similarity measure for two elements.
#
# The SQV (Scalable Quality Value) measures similarity between two elements.
# Unlike normal SQV, the denominator uses the maximum of both values to ensure symmetry:
# \f$ SQV(q_1, q_2) = \frac{1}{1 + \sqrt{\frac{(q_1 - q_2)^2}{f \cdot \max(|q_1|, |q_2|) + \epsilon}}} \f$
#
# @param vec_q1 First time-series vector.
# @param vec_q2 Second time-series vector.
# @param f Scaling factor to normalize differences (default: 1000).
# @param flag_mean If True, returns the mean SQV value; otherwise, returns element-wise SQV values.
# @return The mean SQV value if `flag_mean=True`, else a numpy array of SQV values.
def sqv_counts(vec_q1, vec_q2, f=1000, flag_mean: bool = True):
    mask = ~np.isnan(vec_q1) & ~np.isnan(vec_q2)  # Ignore NaN values
    if np.sum(mask) == 0:
        return np.nan  # No valid values to compare

    ## @var diff
    #  The difference between corresponding elements in vec_q1 and vec_q2.
    diff = vec_q1[mask] - vec_q2[mask]

    ## @var sqv
    #  The computed SQV similarity measure for valid elements.
    sqv = 1 / (1 + np.sqrt((np.square(diff)) / (f * np.maximum(np.abs(vec_q1[mask]),
                                                               np.abs(vec_q2[mask])) + 1e-308)))

    return sqv.mean() if flag_mean else sqv


## @brief Computes the Euclidean distance between two time-series vectors while ignoring NaN values.
#
# The Euclidean distance is calculated as:
# \f$ d = \sqrt{\sum (x_i - y_i)^2} \f$
#
# @param vec1 First time-series vector.
# @param vec2 Second time-series vector.
# @param flag_mean If True, returns the Euclidean norm; otherwise, raises an error.
# @return The Euclidean distance value.
def euclidean(vec1: np.ndarray, vec2: np.ndarray, flag_mean: bool = True):
    mask = ~np.isnan(vec1) & ~np.isnan(vec2)
    if np.sum(mask) == 0:
        return np.nan

    return np.linalg.norm(vec1[mask] - vec2[mask]) if flag_mean else \
        ValueError("Noch nicht implementiert")

# todo kmeans algo mit geh