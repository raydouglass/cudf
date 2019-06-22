/*
 * Copyright (c) 2019, NVIDIA CORPORATION.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef CUDF_REDUCTION_OPERATORS_CUH
#define CUDF_REDUCTION_OPERATORS_CUH

#include <cudf/cudf.h>
#include <utilities/cudf_utils.h>
#include <utilities/wrapper_types.hpp>
#include <utilities/error_utils.hpp>
#include <iterator/iterator.cuh>

#include <utilities/device_operators.cuh>

#include <cmath>

namespace cudf {
namespace reductions {

// intermediate data structure to compute `var`, `std`
template<typename ResultType>
struct var_std
{
    ResultType value;                /// the value
    ResultType value_squared;        /// the value of squared

    CUDA_HOST_DEVICE_CALLABLE
    var_std(ResultType _value=0, ResultType _value_squared=0)
    : value(_value), value_squared(_value_squared)
    {};

    using this_t = cudf::reductions::var_std<ResultType>;

    CUDA_HOST_DEVICE_CALLABLE
    this_t operator+(this_t const &rhs) const
    {
        return this_t(
            (this->value + rhs.value),
            (this->value_squared + rhs.value_squared)
        );
    };

    CUDA_HOST_DEVICE_CALLABLE
    bool operator==(this_t const &rhs) const
    {
        return (
            (this->value == rhs.value) &&
            (this->value_squared == rhs.value_squared)
        );
    };
};

// transformer for `struct var_std` in order to compute `var`, `std`
template<typename ResultType>
struct transformer_var_std
{
    using OutputType = cudf::reductions::var_std<ResultType>;

    CUDA_HOST_DEVICE_CALLABLE
    OutputType operator() (ResultType const & value)
    {
        return OutputType(value, value*value);
    };
};

// ------------------------------------------------------------------------
// difinitions of device struct for binary operation

namespace op {

struct sum {
    using Op = cudf::DeviceSum;

    template<bool has_nulls, typename ElementType, typename ResultType>
    static auto make_iterator(gdf_column const& column, ResultType identity)
    {
        return cudf::make_iterator<has_nulls, ElementType, ResultType>(column, identity);
    }
};

struct product {
    using Op = cudf::DeviceProduct;

    template<bool has_nulls, typename ElementType, typename ResultType>
    static auto make_iterator(gdf_column const& column, ResultType identity)
    {
        return cudf::make_iterator<has_nulls, ElementType, ResultType>(column, identity);
    }
};

struct sum_of_squares {
    using Op = cudf::DeviceSum;

    template<bool has_nulls, typename ElementType, typename ResultType>
    static auto make_iterator(gdf_column const& column, ResultType identity)
    {
        auto it_raw = cudf::make_iterator<has_nulls, ElementType, ResultType>(column, identity);
        return thrust::make_transform_iterator(it_raw,
            cudf::transformer_squared<ResultType>{});
    }
};

struct min {
    using Op = cudf::DeviceMin;

    template<bool has_nulls, typename ElementType, typename ResultType>
    static auto make_iterator(gdf_column const& column, ResultType identity)
    {
        return cudf::make_iterator<has_nulls, ElementType, ResultType>(column, identity);
    }
};

struct max {
    using Op = cudf::DeviceMax;
    
    template<bool has_nulls, typename ElementType, typename ResultType>
    static auto make_iterator(gdf_column const& column, ResultType identity)
    {
        return cudf::make_iterator<has_nulls, ElementType, ResultType>(column, identity);
    }
};

// operator for `mean`
struct mean {
    using Op = cudf::DeviceSum;

    template<bool has_nulls, typename ElementType, typename ResultType>
    static auto make_iterator(gdf_column const& column, ResultType identity)
    {
        return cudf::make_iterator<has_nulls, ElementType, ResultType>(column, identity);
    }

    template<typename ResultType>
    struct intermediate{
        using IntermediateType = ResultType;

        // compute `mean` from intermediate type `IntermediateType`
        static ResultType compute_result(const IntermediateType& input, gdf_size_type count, gdf_size_type ddof)
        {
            return (input / count);
        };

    };
};

// operator for `variance`
struct variance {
    using Op = cudf::DeviceSum;

    template<bool has_nulls, typename ElementType, typename ResultType>
    static auto make_iterator(gdf_column const& column, ResultType identity)
    {
        auto transformer = cudf::reductions::transformer_var_std<ResultType>{};
        auto it_raw = cudf::make_iterator<has_nulls, ElementType, ResultType>(column, identity);
        return thrust::make_transform_iterator(it_raw, transformer);
    }

    template<typename ResultType>
    struct intermediate{
        using IntermediateType = var_std<ResultType>;

        // compute `variance` from intermediate type `IntermediateType`
        static ResultType compute_result(const IntermediateType& input, gdf_size_type count, gdf_size_type ddof)
        {
            ResultType mean = input.value / count;
            ResultType asum = input.value_squared;
            gdf_size_type div = count -ddof;
            ResultType var = asum / div - ((mean * mean) * count) /div;

            return var;
        };
    };
};

// operator for `standard deviation`
struct standard_deviation {
    using Op = cudf::DeviceSum;

    template<bool has_nulls, typename ElementType, typename ResultType>
    static auto make_iterator(gdf_column const& column, ResultType identity)
    {
        auto transformer = cudf::reductions::transformer_var_std<ResultType>{};
        auto it_raw = cudf::make_iterator<has_nulls, ElementType, ResultType>(column, identity);
        return thrust::make_transform_iterator(it_raw, transformer);
    }
    template<typename ResultType>
    struct intermediate{
        using IntermediateType = var_std<ResultType>;

        // compute `standard deviation` from intermediate type `IntermediateType`
        static ResultType compute_result(const IntermediateType& input, gdf_size_type count, gdf_size_type ddof)
        {
            using intermediateOp = typename cudf::reductions::op::variance::template intermediate<ResultType>;
            ResultType var = intermediateOp::compute_result(input, count, ddof);

            return static_cast<ResultType>(std::sqrt(var));
        };
    };
};
} // namespace op


} // namespace reductions
} // namespace cudf

#endif