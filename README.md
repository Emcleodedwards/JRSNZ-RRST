# JRSNZ-RRST
# JRSNZ - Processing and Analysis of RRST data

Aim of project was to develop an analytical protocol to capture measures of interoceptive sensitivity more robustly in the breathing (inspiratory resistance) domain, by better accounting for physiological variability. This extends on previous interoceptive breathing protocols by capturing and accounting for inherent intra- and inter-participant physiological variability, and provides the ability to standardise this measure for cross-modal comparisons.

Project includes MatLab code for processing physiological breathing data collected using the [RRST](https://www.sciencedirect.com/science/article/pii/S0301051122000679) (Nikolova et al., 2022), and the statistical analysis completed in R for the paper titled 'Incorporating Physiological Variance within Estimations of Interoceptive Sensitivity'.

## Table of Contents

- [Overview](#overview)
- [Usage](#usage)
- [License for Intersections](#license)

---

## Overview

**Script Overview**:
- `RRST_analysis_master.m`: This script runs the analysis for the physiological and perceptual data related to the Respiratory Resistance Sensitivity Task.
- `RRST_calcMetrics.m`: This script calculates the summary interoceptive metrics for the Respiratory Resistance Sensitivity Task.
- `RRST_extractBehaviour.m`: This script is to extract behavioural data from RRST `.beh` file. 
- `RRST_extractPhysiology.m`: This script extracts physiological data from the RRST `.physio` file (LabChart recording).
- `RRST_setOptions.m`: This script sets required paths. 
- `JRSNZ-analysis.Rmd`: R Markdown file of analysis conducted for JRSNZ article, including analysis of questionnaire data. 

## Usage
MatLab scripts are used for the analysis of physiological and perceptual data related to the Respiratory Resistance Sensitivity Task (Nikolova et al., 2022). The code will extract resistance and pressure related sensitivity metrics (derived from the Weibull psychometric function, based on Weber contrast values used as stimulus intensity levels), interoceptive sensibility metrics, and interoceptive insight metrics. 

All scripts are required (`RRST_analysis_master`, `RRST_calcMetrics`, `RRST_extractBehaviour`, `RRST_extractPhysiology`, and `RRST_setOptions`) for the analysis to run successfully. 

Before running the code: 
1. Ensure file pathways in `RRST_setOptions` are correctly set to where your files are located e.g., specify `options.paths.root`, `.dataFolder`, `.outputFolder`, `.figureFolder`, and `.scriptFolder`. 
2. Specify the required PPID on line 41  of `RRST_analysis_master` e.g.,  `RRST.options.PPIDs = {'0014', '0015'};`
3. Ensure required dependencies have been downloaded/installed and are accessible.

### Dependencies for MatLab Scripts
The following external scripts/toolboxes were used in this project. 

- `RousseeuwCrouxSn.m` by [Pete R Jones]([https://www.helsinki.fi/assets/drupal/2024-04/Jones.pdf](https://www.helsinki.fi/assets/drupal/2024-04/Jones.pdf)) under the [CC4.0 License]([creativecommons.org/licenses/by/4.0/](http://creativecommons.org/licenses/by/4.0/)). An adapted version of the script (adapted to accomodate NaN values) was used for outlier identification.
- `intersections.m` by [Douglas M. Schwarz]([https://au.mathworks.com/matlabcentral/fileexchange/11837-fast-and-robust-curve-intersections](https://au.mathworks.com/matlabcentral/fileexchange/11837-fast-and-robust-curve-intersections)), version 2.0.0.0 2.0, 25 May 2017.  See [License](#License for Intersections), Copyright (c) 2017, Douglas M. Schwarz. All rights reserved. Used to plot psychometric function grand mean in `RRST_analysis_master`. 
- `Palamedes Toolbox` by [Nicolaas Prins and Frederick Kingdom]([https://palamedestoolbox.org/download.html](https://palamedestoolbox.org/download.html)). Version 1.11.11, used for `PAL_Weibull` function. 
- `Psychtoolbox-3` by [Mario Kleiner, David Brainard, Denis Pelli, Chris Broussard, Tobias Wolf, and Diederick Niehorster](http://psychtoolbox.org/overview.html) (used for the `FitWeibAlphTAFC` in `RRST_calcMetrics`)
 
---
## License

```markdown
Copyright (c) 2017, Douglas M. Schwarz
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution

* Neither the name of University of Rochester nor the names of its
  contributors may be used to endorse or promote products derived from this
  software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```

---
