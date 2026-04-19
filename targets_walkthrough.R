## {targets} template

# create project file directory

# for a project with many, arbitrary number of files per id, it does make sense 
# to nest files within folders by `id`

# 📂 project/                 # top-level project folder
# ├── 📂 raw data/            # original, untouched source files
# |   └── 📂 id01             # nested data folders by id
# |       └── 📄 id01-yyyy-mm-dd.xlsx
# ├── 📂 processed data/      # cleaned/transformed datasets used for analysis
# ├── 📂 documents/           # study documents, consent forms, etc.
# ├── 📂 figures/             # exported plots, figures
# ├── 📂 R/                   # .R scripts in the targets pipeline
# |   ├── 📄 0_helpers.R      # small repeated helper functions
# |   ├── 📄 1_processing.R   # processing/cleaning functions
# |   ├── 📄 2_analysis.R     # analysis functions
# |   └── 📄 3_plots.R        # plotting functions
# ├── 📂 exploratory/         # .R scripts not part of the targets pipeline
# |   └── 📄 test-analysis.R  # a test script
# └── 📄 project.Rproj        # create R studio project

# ⚠️ if using Git and GitHub, the data folders will need to be separated
# from the R script folders, but ignore this for now.

# my preferred unique file naming format: `id-yyyy-mm-dd.xlsx`
# additional identifiers as necessary `id-trial-device-yyy-mm-dd.xlsx`


## Install {targets}
install.packages(c("targets", "tarchetypes"))

# in R console run:
targets::use_targets()
# this creates a new file `_targets.R` at project root
# this file defines the structure of the targets pipeline, with instructions

# the targets pipeline is another layer of abstraction on top of the functions
# & scripts we are building. We can't directly see the environment in the
# pipeline (libraries loaded, saved objects, etc.). This makes things harder
# to troubleshoot inside the pipeline, so we want to troubleshoot outside the
# pipeline first and make sure the environment inside is what we think it is.

# create another .R script in the project root `run.R`
# Use this to run and troubleshoot the pipeline

# add the following four calls to `run.R`:

# this displays the network map of pipeline functions and saved objects
targets::tar_visnetwork()

# this runs the target according to the `_targets.R` file
# `targets.R` and all source .R scripts should be updated and saved 
# before (re-)running the pipeline
targets::tar_make()
# running `tar_make()` is the same as running everything in the `_targets.R` 
# file

# these two display any errors or warnings returned by the pipeline
print(targets::tar_meta(fields = error, complete_only = TRUE), n = Inf)
print(targets::tar_meta(fields = warnings, complete_only = TRUE), n = Inf)

# project root now includes these new .R files
# 📂 project/
# ├── ...
# ├── 📄 _targets.R
# └── 📄 run.R

## `_targets.R`

# `_targets.R` is the structure of the targets pipeline

# see the demo `_targets.R` in this template repo

# `tar_source()` sources (runs) all .R scripts in the R/ folder
# eventually, your helper, processing, analysis, and plotting functions will
# live in here and be 'sourced' (ready to operate) when you call the pipeline
# with `tar_make()`.

# `tar_target()` calls will perform a function over inputs, and return a named
# object, which can then be fed into the next `tar_target()` level of operations

# separate sublists of `tar_target` calls to more easily organise them, e.g.
# similar to the `*.R` naming convention. Then execute all sublists at the end 
# of the `_targets.R` script, e.g.:

list(
    processing,
    analysis,
    plotting,
    results
)
# results -> I use this step to aggregate per-item results at the end of the 
#    pipeline, e.g. summary data per date per id, and save to a single file

# `tar_map()` iterates over a static (pre-defined) list of identifiers stored 
# in `values`; in this case `values = list(id = ids)`. This is the key to 
# writing a function once and op11erating that function over all participants. 
# This is called static branching. See: https://books.ropensci.org/targets/static.html

# with a large number of files per id, it makes sense to also use dynamic 
# branching (see: https://books.ropensci.org/targets/dynamic.html). This uses 
# `pattern = map(...)` in `tar_targets()` to iterate over the objects in the 
# `map()` call; in this case file paths within each `id` folder.

## Retrieving intermediate objects

# each `tar_targets()` saves the returned intermediate object as a semi-hidden .
# rds file (unless `format = file`, which directs target to a real file in your 
# folder structure). These intermediate objects are stored in `_targets/
# objects` and can be retrieve/read by calling, e.g.:

tar_read(parvo_data_TW11)

# note the object name "parvo_data" is appended with the `tar_map()` id value; 
# e.g. `parvo_data_TW11`. Because this is a dynamically branched object, it 
# calls a list of multiple data frames for each file within `TW11` folder.

# `tar_combine()` takes in all iterations of an object from a `tar_map()` 
# pipeline and aggregates them. In the current example, simply takes each 
# `vo2_summary_row`, which is a single row for each `id-date` and binds them 
# into a single data frame will all `id` and `date` files. Then saves this data 
# frame as `vo2_summary.xlsx`.

## Functions in `R/`

# `1_processing.R` contains a simple function which takes in a previously 
# created data frame and identifiers, and returns a single-row summarising data 
# frame with unique identifiers.

# analyse the data first manually, then break the analysis process down into 
# logical chunks with intermediate data which might be important to keep 
# available: e.g. `parvo_data` may be re-used multiple times, so we want to 
# save it as an intermediate object. Wrap these analysis chunks as functions 
# with logical inputs and returned outputs (functional programming is a topic 
# for another time). Keep these funtions in `R/` to be called by the pipeline 
# and run iteratively over each file.