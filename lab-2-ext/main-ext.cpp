#include <deal.II/base/convergence_table.h>

#include <fstream>
#include <iostream>
#include <vector>

#include "Poisson1D-ext.hpp"

int main(int argc, char * argv[])
{
    ConvergenceTable table;

    // Ask user for smooth or non-smooth case (or use argv[1] if provided)
    std::string case_type;
    std::cout << "Choose case ([s]mooth/[n]on-smooth): ";
    std::getline(std::cin, case_type);
    if (case_type == "s" || case_type == "S" || case_type == "smooth" || case_type.empty()) {
        case_type = "smooth";
    } else if (case_type == "n" || case_type == "N" || case_type == "non-smooth" || case_type == "nonsmooth") {
        case_type = "non-smooth";
    } else {
        std::cout << "Invalid input. Defaulting to 'smooth'." << std::endl;
        case_type = "smooth";
    }

    const std::vector<unsigned int> N_values = {9, 19, 39, 79, 159, 319};

    std::ofstream convergence_file("convergence.csv");
    convergence_file << "h,eL2,eH1" << std::endl;

    for (const unsigned int &N : N_values)
    {
        const std::string parameter_file = std::string(__FILE__).substr(
            0, std::string(__FILE__).find_last_of("/\\")
        ) + "/" + case_type + "/poisson1d-" + std::to_string(N) + ".prm";
        Poisson1DExt problem(parameter_file);

        problem.setup();
        problem.assemble();
        problem.solve();
        problem.output();

        const double h        = 1.0 / (N + 1.0);
        const double error_L2 = problem.compute_error(VectorTools::L2_norm);
        const double error_H1 = problem.compute_error(VectorTools::H1_norm);

        table.add_value("h", h);
        table.add_value("L2", error_L2);
        table.add_value("H1", error_H1);

        convergence_file << h << "," << error_L2 << "," << error_H1 << std::endl;
    }

    table.evaluate_all_convergence_rates(ConvergenceTable::reduction_rate_log2);

    table.set_scientific("L2", true);
    table.set_scientific("H1", true);

    table.write_text(std::cout);

    return 0;
}
