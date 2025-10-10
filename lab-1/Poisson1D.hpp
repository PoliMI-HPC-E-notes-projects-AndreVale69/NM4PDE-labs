#ifndef POISSON1D_HPP
#define POISSON1D_HPP

#include <deal.II/base/function.h>
#include <deal.II/base/quadrature_lib.h>

#include <deal.II/dofs/dof_handler.h>
#include <deal.II/fe/fe_q.h>

#include <deal.II/grid/tria.h>

#include <deal.II/lac/sparsity_pattern.h>
#include <deal.II/lac/sparse_matrix.h>
#include <deal.II/lac/vector.h>

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
    double value(const Point<dim> &p, const unsigned int = 0) const override {
      const double x = p[0];
      return (x > 1.0/8.0 && x <= 1.0/4.0) ? -1.0 : 0.0;
    }
  };

  // Constructor: N = (N+1) elements on [0,1], r = FE degree.
  Poisson1D(const unsigned int &N_, const unsigned int &r_)
    : N(N_), r(r_) {}

  // FEM pipeline (defined later).
  void setup();    // mesh, FE, DoFs, sparsity, allocate A,f,u
  void assemble(); // local integrals → global A,f and apply Dirichlet
  void solve();    // linear solver (CG)
  void output() const; // VTK write

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