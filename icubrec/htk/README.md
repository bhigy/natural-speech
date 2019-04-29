## iCubrec - HTK

This folder contains the first version of the command recognition pipeline
which is based on the [Hidden Markov Model ToolKit
(HTK)](http://htk.eng.cam.ac.uk/). As HTK doesn't allow live recognition with
deep neural networks (DNNs), it is based on Gaussian mixture models (GMMs)
instead.

A good starting point is [the demo](DEMO.md) on offline decoding with a
pretrained model. A tutorial explaining the full pipeline to train an ASR
system on Wall Street Journal (WSJ) dataset is available in [this other
tutorial](TUTORIAL.md).

## Code organization

The code is organized in several subfolders as follows:
* `gmm_training` provides code to train Gaussian Mixture Models (GMM).
* `dnn_training` contains scripts to train Deep Neural Network (DNN) based
  models.  Two alternatives are offered here: training the net with HTK (`htk`
subfolder) or with Tensorflow (`tf` subfolder). Instructions on how to convert
a net trained with Tensorflow for use in HTK are provided in
[`offline_decoding/README.md`](offline_decoding#how-to-convert-tf-net-to-htk-format).
* `offline_decoding` contains tools to test your system offline (GMM- or
  DNN-based).
* `yarp_decoding` provides the utilities to run the model online within yarp.

Additionaly to those, several "utility" subfolders are also present:
* `common` contains configuration and template files required by the scripts
  mentionned above.
* `scripts` provides generic utility scripts common to different subfolders.

## Dependencies

The code proposed here is based on the Hidden Markov Model ToolKit (HTK)
version 3.5. The toolkit can be downloaded for [HTK's
website](http://htk.eng.cam.ac.uk/).

## Environment files

To make the scripts more flexibles, we use several environment variables. They
mainly fall into two groups:
* default file locations that will vary from one computer to the other or from
  one dataset to the other.
* options in the training procedure.

We use to define those environment variables in configuration files whose file
extension is `.env`. Grouping the environment variables in files makes it easy
to repeat experiments and switch between them. Those environment files can then
be used in two different ways:
* all the main scripts offered here accept a `-e` option to provide an
  environment file. This file will be automatically loaded from the script
(leaving the shell environment clean after the execution of the script).
* alternatively, one can load the environment file in the shell's environment
  before running the script, using the command `source <file.env>`. This
allows the user to easily modify some parameters on-the-fly, without the need
to modify the original environment file.

We offer default environment files to train and test models with standard
datasets (see the different subfolders for more details about the specific
experiments supported). They all depend on the file `sys_dpdt.env` (present in
this folder) that contains the system dependent variables (files locations and
computer configuration). The user will have to adapt this file to his own
configuration before running the scripts.

## Auxiliary scripts

Finally, this folder contains scripts to perform some generic auxiliary tasks:
* extracting feature
* building the dictionary and the word network

We briefly talk about them know.

### Feature extraction

Generaly speaking, this step is optional as the feature extraction can be
performed on-the-fly by HTK tools. But to fasten the training or the testing,
we precompute the features and save them on the disk. Features can be extracted
using the script `extract_feat.sh`.

For example, to extract MFCC features for WSJ (MFCC are usually used to train
GMMs), you can run the command:

    ./extract_feat.sh -e gmm_traning/wsj0_5k.env output_folder

### Preparing the dictionary and the language model

To perform speech recognition, we will need two additional resources:
* a dictionary that gives the sequence(s) of phonemes corresponding to each
  word in the vocabulary we are considering for the task at hand.
* a word network (our language model) that will define which combination of
  words is a valid sentence.

#### Preparing CMU dictionary

Our scripts are based on the CMU dictionary v0.6x (e.g. v0.6d), downloadable
from [CMU's website](http://www.speech.cs.cmu.edu/cgi-bin/cmudict). The file
should be placed under `$HTK_DATA/cmu/` folder and called `c0.6`.

Before using the dictionary, the file need to be converted to a better format
and a few issues need to be fixed (see `scripts/FixCMUDict.pl` for more details
about the modifications we're doing). This can conveniently be done with the
script `prep_cmu_dict.sh`. From `icubrec` folder, one can simply issue the
command:

    ./prep_cmu_dict.sh -e gmm_training/wsj0_5k.env

As a result, the folder `$HTK_DATA/cmu/` will contain three new files: `cmu6`
which is the cleaned version of the dictionary, `cmu6sp` which additionally
contains sp short pauses after each word and `cmu6spsil` which also maps the
word "silence" the phone "sil".

#### Building the resources

Once the dictionary downloaded and preprocessed, we can adapt it to our
vocabulary and compute the word network.  For WSJ and chime4 datasets, the
script `build_lm_wsj.sh` can be used for that purpose.
