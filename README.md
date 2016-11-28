# Learning from Maps: Visual Common Sense for Autonomous Driving

<img src="http://www.cs.princeton.edu/~aseff/mapnet/img/teaser.jpg" width="400">

Given a street view image, our model learns to estimate a set of driving-relevant road layout attributes.
The ground truth attribute labels for model training are automatically extracted from OpenStreetMap.

Project page: http://www.cs.princeton.edu/~aseff/mapnet

PDF: https://arxiv.org/abs/1611.08583

### Citation 
```
@article{seffxiao2016,
  title={Learning from Maps: Visual Common Sense for Autonomous Driving},
  author={Seff, Ari and Xiao, Jianxiong},
  journal={arXiv preprint arxiv:1611.08583},
  year={2016}
}
```

### Requirements
- Python 2.7 or later
- Matlab
- [Marvin](https://github.com/PrincetonVision/marvin)

### Instructions
`main.m` demonstrates the full pipeline for downloading images from Google Street View, establishing correspondence with OpenStreetMap roads for label extraction, and training models for road attribute estimation.

**Dataset and pre-trained networks**: The dataset consisting of Google Street View panoramas and ground truth road attribute labels as well as pre-trained networks are available for download from http://www.cs.princeton.edu/~aseff/mapnet
