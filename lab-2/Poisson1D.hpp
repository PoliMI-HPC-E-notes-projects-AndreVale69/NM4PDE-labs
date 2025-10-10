#ifndef POISSON1D_HPP
#define POISSON1D_HPP

#include <deal.II/base/function.h>
#include <deal.II/dofs/dof_handler.h>
#include <deal.II/grid/tria.h>
#include <deal.II/lac/sparsity_pattern.h>
#include <deal.II/lac/sparse_matrix.h>
#include <deal.II/lac/vector.h>
#include <deal.II/dofs/dof_tools.h>
#include <deal.II/fe/fe_values.h>
#include <deal.II/grid/grid_generator.h>
#include <deal.II/lac/precondition.h>
#include <deal.II/lac/solver_cg.h>
#include <deal.II/numerics/matrix_tools.h>
#include <deal.II/numerics/vector_tools.h>

#include <memory>

using namespace dealii;

/**
 * Minimal Poisson 1D solver skeleton.
 * Only the core fields from our math → deal.II mapping.
 */
class Poisson1D
{
public:
  // Physical dimension (1D, 2D, 3D)
  static constexpr unsigned int dim = 1;

  // μ(x) — diffusion coefficient (Lab 01: μ ≡ 1).
  class DiffusionCoefficient : public Function<dim>
  {
  public:
    // Constructor.
    DiffusionCoefficient() = default;

    // Evaluation.
    double value(const Point<dim> &, const unsigned int = 0) const override {
      return 1.0;
    }
  };

  // f(x) — forcing term (Lab 01: -1 on (1/8, 1/4], 0 elsewhere).
  class ForcingTerm : public Function<dim>
  {
  public:
    // Constructor.
    ForcingTerm() = default;

    // Evaluation.
    virtual double
    value(const Point<dim> &p,
          const unsigned int /*component*/ = 0) const override
    {
      // Points 3 and 4.
      return 4.0 * M_PI * M_PI * std::sin(2.0 * M_PI * p[0]);

      // Point 5.
      // if (p[0] < 0.5)
      //   return 0.0;
      // else
      //   return -std::sqrt(p[0] - 0.5);
    }
  };

  // Exact solution.
  class ExactSolution : public Function<dim>
  {
  public:
    // Constructor.
    ExactSolution()
    {}

    // Evaluation.
    virtual double
    value(const Point<dim> &p,
          const unsigned int /*component*/ = 0) const override
    {
      // Points 3 and 4.
      return std::sin(2.0 * M_PI * p[0]);

      // Point 5.
      // if (p[0] < 0.5)
      //   return A * p[0];
      // else
      //   return A * p[0] + 4.0 / 15.0 * std::pow(p[0] - 0.5, 2.5);
    }

    // Gradient evaluation.
    // deal.II requires this method to return a Tensor (not a double), i.e. a
    // dim-dimensional vector. In our case, dim = 1, so that the Tensor will in
    // practice contain a single number. Nonetheless, we need to return an
    // object of type Tensor.
    virtual Tensor<1, dim>
    gradient(const Point<dim> &p,
             const unsigned int /*component*/ = 0) const override
    {
      Tensor<1, dim> result;

      // Points 3 and 4.
      result[0] = 2.0 * M_PI * std::cos(2.0 * M_PI * p[0]);

      // Point 5.
      // if (p[0] < 0.5)
      //   result[0] = A;
      // else
      //   result[0] = A + 2.0 / 3.0 * std::pow(p[0] - 0.5, 1.5);

      return result;
    }

    static constexpr double A = -4.0 / 15.0 * std::pow(0.5, 2.5);
  };

  // Constructor: N = (N+1) elements on [0,1], r = FE degree.
  Poisson1D(const unsigned int &N_, const unsigned int &r_)
    : N(N_), r(r_) {}

  // FEM pipeline (defined later).
  void setup();    // mesh, FE, DoFs, sparsity, allocate A,f,u
  void assemble(); // local integrals → global A,f and apply Dirichlet
  void solve();    // linear solver (CG)
  void output() const; // VTK write
  // Compute the error.
  double compute_error(const VectorTools::NormType &norm_type) const;

protected:
  // Discretization parameters
  const unsigned int N; // N+1 elements
  const unsigned int r; // polynomial degree

  // Problem data
  DiffusionCoefficient diffusion_coefficient;
  ForcingTerm          forcing_term;

  // Geometry & FE space
  Triangulation<dim>                  mesh;
  std::unique_ptr<FiniteElement<dim>> fe;           // e.g., FE_Q<dim>(r)
  std::unique_ptr<Quadrature<dim>>    quadrature;   // e.g., QGauss<dim>(r+1)
  DoFHandler<dim>                     dof_handler;

  // Algebraic objects: A u = f
  SparsityPattern      sparsity_pattern;
  SparseMatrix<double> system_matrix;
  Vector<double>       system_rhs;
  Vector<double>       solution;
};

#endif //POISSON1D_HPP