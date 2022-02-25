# meeg_analysis
Scripts for M/EEG preprocessing, source reconstruction, and analysis

|   |
| :--- |
| **Note:** These scripts require FieldTrip (https://www.fieldtriptoolbox.org/). [^fieldtrip] |  |

[^fieldtrip]: Any version _might_ work, but the current scripts have been tested using FieldTrip-20200130 and Matlab R2019b.

This repository contains the scripts developed (and, some times, compiled) in the [Laboratory of Cognitive and Computational Neuroscience](https://meg.ucm.es) in Madrid for the analysis of MEG and EEG data. Code based on others' is (or should be) referenced at the beginning of the code, and is (or should be) always based on Open Source code [^opensource].

[^opensource]: Althought not explicitely indicated in each code file, all code present here is open source, publised under the GNU GPL v.3 license.

The repository is divided in sections (namely folders starting by the letter "s"), and each sesion is divided in steps (namely scripts starting by the letter "s". It is confussing, I know).

The sections included are:

### Pre-Maxilter *bad channel* detection (or s0)
MaxFilter (really tSSS) is a spatial filter developed by Neuromag and part of MEGIN (previously Neuromag or Elekta) MEG systems. As a spatial filter, is extremely sensitive to *broken channels* (i.e., channels containing false data, generally introduced by faulty electronics or broken sensors).

Code in this section allows for the detection of these *broekn channels*, and the creation of batch scripts to apply MaxFilter to the data.

You can find a complete guide to this code in the [wiki](../../wiki).

### Preprocessing of the data (or s1)
Preprocessing here is the procedure of detect and remove noise present in the data. This noise can present as broken channels, artifacts (biological or otherwise) or external noise.

Code in this section allows for the identification of broken channels, artifacts or noisy independent components, and the generation of files containing only clean data.

You can find a complete guide to this code in the [wiki](../../wiki).

### Source reconstruction (or s2)
Source reconstruction is the procedure to identify the origin of the electrphysiological activity recorded by the channels. It can be based on anatomical information of the participant or on a standard template head.

Code in this section allows for the generation of realistic head models from anatomical images (MRI or CT) of the participants or from standard template heads, and for the reconstruction of the electrphysiological activity using these head models and many forward and inverse models.

You can find a complete guide to this code in the [wiki](../../wiki).
