#ifndef POISSON1D_EXT_HPP
#define POISSON1D_EXT_HPP

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

// header
#include <deal.II/base/function_parser.h>
#include <deal.II/base/parameter_handler.h>


using namespace dealii;

class Poisson1DExt
{
public:
    // Physical dimension (1D, 2D, 3D)
    static constexpr unsigned int dim = 1;

    /**
     * Constructor: read parameters from input file.
     * @param filename Input file name.
     */
    explicit Poisson1DExt(const std::string &filename) {
        declare_parameters();
        prm.parse_input(filename);
        mu_expr = prm.get("mu");
        f_expr = prm.get("f");
        exact_solution_expr = prm.get("exact_solution");
        N = prm.get_integer("N");
        r = prm.get_integer("degree");
    }

    // override setup
    void setup();    // mesh, FE, DoFs, sparsity, allocate A,f,u
    void assemble(); // local integrals → global A,f and apply Dirichlet
    void solve();    // linear solver (CG)
    void output() const; // VTK write
    // Compute the error.
    double compute_error(const VectorTools::NormType &norm_type) const;
protected:
    /**
     * Declare the parameters we want to read from the input file.
     */
    void declare_parameters() {
        prm.declare_entry("mu", "1.0", Patterns::Anything(),
                      "Diffusion coefficient mu(x)");
        prm.declare_entry("f", "4*pi*pi*sin(2*pi*x)", Patterns::Anything(),
                          "Right-hand side f(x)");
        prm.declare_entry("exact_solution", "sin(2*pi*x)", Patterns::Anything(),
                          "Exact solution (for error computation)");
        prm.declare_entry("degree", "1", Patterns::Integer(1, 5),
                          "Polynomial degree of FE_Q<1>");
        prm.declare_entry("N", "10", Patterns::Integer(2),
                          "Number of subintervals");
    }

    // Discretization parameters
    unsigned int N; // N+1 elements
    unsigned int r; // polynomial degree

    ParameterHandler prm;

    // Parsed expressions; initialized in setup()
    std::string mu_expr, f_expr, exact_solution_expr;

    // μ(x) — diffusion coefficient
    FunctionParser<dim> mu_function;
    // f(x) — forcing term
    FunctionParser<dim> rhs_function;
    // u(x) — exact solution (for error computation)
    FunctionParser<dim> exact_solution_function;

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

#endif //POISSON1D_EXT_HPP