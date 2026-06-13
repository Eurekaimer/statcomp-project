# results

This directory stores generated experiment outputs used for result inspection and figure generation.

## Subdirectories

- `tables/`: metric CSV files and summary CSV files.
- `figures/`: generated plots.
- `raw/`: raw RDS objects for individual experiment cases.
- `logs/`: runtime logs and failure records.
- `checkpoints/`: resumable experiment caches.

Experiment scripts reuse complete result tables when available. The main result index is stored in `results/RESULT_INDEX.md`.
