###############################################################################
# Count the number of logfiles in each of the deepest subdirectories of the
# slurm/logs/ directory.
#
# gives a summary of how many logfiles were created during the run of the
# workflow, and how many subdirectories had more than one logfile (indicating 
# possible job restarts).
#
# @author:charles.hefer@agresearch.co.nz
# @version:0.2
###############################################################################
import os
import optparse
from collections import defaultdict


def count_logfiles_in_directory(directory_path):
    """Count .log files in a directory and return the count and file list."""
    try:
        files = os.listdir(directory_path)
        log_files = [f for f in files if f.endswith('.log')]
        return len(log_files), log_files
    except OSError as e:
        print(f"Error accessing directory {directory_path}: {e}")
        return 0, []


def analyze_slurm_logs(slurm_logs_path, output_file=None, verbose=False):
    """
    Parse the slurm/logs directory and analyze log file counts.
    
    Args:
        slurm_logs_path (str): Path to the slurm/logs directory
        output_file (str): Optional output file path
        verbose (bool): Show detailed processing information
    """
    results = {}
    total_directories = 0
    directories_with_multiple_logs = 0
    total_log_files = 0
    
    if not os.path.exists(slurm_logs_path):
        print(f"Error: Directory {slurm_logs_path} does not exist!")
        return
    
    # Navigate through rule directories
    for rule_dir in sorted(os.listdir(slurm_logs_path)):
        rule_path = os.path.join(slurm_logs_path, rule_dir)
        
        if not os.path.isdir(rule_path):
            if verbose:
                print(f"Skipping non-directory: {rule_dir}")
            continue
            
        if verbose:
            print(f"Processing rule directory: {rule_dir}")
            
        results[rule_dir] = {}
        rule_dir_count = 0
        
        # Navigate through job number subdirectories
        for job_subdir in sorted(os.listdir(rule_path), key=lambda x: int(x) if x.isdigit() else float('inf')):
            job_path = os.path.join(rule_path, job_subdir)
            
            if not os.path.isdir(job_path):
                if verbose:
                    print(f"  Skipping non-directory: {job_subdir}")
                continue
                
            total_directories += 1
            rule_dir_count += 1
            log_count, log_files = count_logfiles_in_directory(job_path)
            
            if verbose:
                print(f"  Job {job_subdir}: {log_count} log files")
            
            results[rule_dir][job_subdir] = {
                'count': log_count,
                'files': log_files,
                'path': job_path
            }
            
            total_log_files += log_count
            
            if log_count > 1:
                directories_with_multiple_logs += 1
                
        if verbose:
            print(f"  Total directories in {rule_dir}: {rule_dir_count}")
            print()
    
    # Generate report
    report_lines = []
    report_lines.append("=" * 60)
    report_lines.append("Snakemake SLURM LOG ANALYSIS REPORT")
    report_lines.append("=" * 60)
    report_lines.append(f"Total directories analyzed: {total_directories}")
    report_lines.append(f"Total log files found: {total_log_files}")
    report_lines.append(f"Directories with multiple logs: {directories_with_multiple_logs}")
    report_lines.append(f"Directories with single logs: {total_directories - directories_with_multiple_logs}")
    report_lines.append("")
    
    if directories_with_multiple_logs > 0:
        report_lines.append("DIRECTORIES WITH MULTIPLE LOG FILES (Job restarted):")
        report_lines.append("-" * 50)
        
        for rule_name, jobs in results.items():
            rule_has_multiples = False
            for job_id, job_data in jobs.items():
                if job_data['count'] > 1:
                    if not rule_has_multiples:
                        report_lines.append(f"\nRule: {rule_name}")
                        rule_has_multiples = True
                    
                    report_lines.append(f"  Job {job_id}: {job_data['count']} log files")
                    for log_file in job_data['files']:
                        report_lines.append(f"    - {log_file}")
        report_lines.append("")
    
    # Summary by rule
    report_lines.append("SUMMARY BY RULE:")
    report_lines.append("-" * 30)
    for rule_name, jobs in results.items():
        rule_total_logs = sum(job['count'] for job in jobs.values())
        rule_total_dirs = len(jobs)
        rule_multiple_dirs = sum(1 for job in jobs.values() if job['count'] > 1)
        
        report_lines.append(f"{rule_name}:")
        report_lines.append(f"  Total directories: {rule_total_dirs}")
        report_lines.append(f"  Total log files: {rule_total_logs}")
        report_lines.append(f"  Directories with multiple logs: {rule_multiple_dirs}")
        report_lines.append("")
    
    # Output results
    report_text = "\n".join(report_lines)
    
    if output_file:
        try:
            with open(output_file, 'w') as f:
                f.write(report_text)
            print(f"Report written to: {output_file}")
        except IOError as e:
            print(f"Error writing to output file {output_file}: {e}")
    else:
        print(report_text)


def __main__():
    """Parse the cmd line options"""
    parser = optparse.OptionParser(
        usage="%prog [options]",
        description="Analyze SLURM log files in subdirectories and identify potential job restarts"
    )
    
    parser.add_option("-i", "--input", default="slurm/logs", dest="input",
                      help="Path to the slurm/logs directory (default: slurm/logs)")
    parser.add_option("-o", "--output", default=None, dest="output",
                      help="Output file path (if not specified, prints to stdout)")
    parser.add_option("-v", "--verbose", action="store_true", dest="verbose",
                      help="Show detailed directory processing information")
    
    (options, args) = parser.parse_args()
    
    analyze_slurm_logs(options.input, options.output, options.verbose)


if __name__ == "__main__":
    __main__()
	