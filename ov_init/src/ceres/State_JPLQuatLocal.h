/*
 * OpenVINS: An Open Platform for Visual-Inertial Research
 * Copyright (C) 2021 Patrick Geneva
 * Copyright (C) 2021 Guoquan Huang
 * Copyright (C) 2021 OpenVINS Contributors
 * Copyright (C) 2019 Kevin Eckenhoff
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#ifndef OV_INIT_CERES_JPLQUATLOCAL_H
#define OV_INIT_CERES_JPLQUATLOCAL_H

#include <ceres/ceres.h>

#include "utils/quat_ops.h"

namespace ov_init {

/**
 * @brief JPL quaternion CERES state parameterization
 */
class State_JPLQuatLocal : public ceres::LocalParameterization {
public:
  bool Plus(const double *x, const double *delta, double *x_plus_delta) const override {

    // Apply the standard JPL update: q <-- [d_th/2; 1] (x) q
    Eigen::Map<const Eigen::Vector4d> q(x);

    // Get delta into eigen
    Eigen::Map<const Eigen::Vector3d> d_th(delta);
    Eigen::Matrix<double, 4, 1> d_q;
    double theta = d_th.norm();
    if (theta < 1e-8) {
      d_q << .5 * d_th, 1.0;
    } else {
      d_q.block(0, 0, 3, 1) = (d_th / theta) * std::sin(theta / 2);
      d_q(3, 0) = std::cos(theta / 2);
    }
    d_q = ov_core::quatnorm(d_q);

    // Do the update
    Eigen::Map<Eigen::Vector4d> q_plus(x_plus_delta);
    q_plus = ov_core::quat_multiply(d_q, q);
    return true;
  }

  bool ComputeJacobian(const double *x, double *jacobian) const override {
    // This essentially "tricks" ceres.
    // Instead of doing what ceres wants, dr/dlocal= dr/dglobal * dglobal/dlocal, we instead directly do:
    // dr/dlocal= [ dr/dlocal, 0] * [I; 0]= dr/dlocal. Therefore we here define dglobal/dlocal= [I; 0]
    Eigen::Map<Eigen::Matrix<double, 4, 3, Eigen::RowMajor>> j(jacobian);
    j.topRows<3>().setIdentity();
    j.bottomRows<1>().setZero();
    return true;
  }

  int GlobalSize() const override { return 4; };

  int LocalSize() const override { return 3; };
};

} // namespace ov_init

#endif // OV_INIT_CERES_JPLQUATLOCAL_H