# Manual Annotations Overview

Relevant files:

- [Codebook](codebook.md)
- [Progress](progress.md)

## Overall approach

Many existing projects would code this with a single codebook extracting the triples directly from text. However, we think that it is best to split the coding into smaller steps to make it easier to code and to make it possible to automate the easier steps (i.e. recognizing actors) while concentrating coding effort on the harder steps. 

Thus, we split the overall coding into four distinct sub-steps:
1. Does the sentence mention a (relevant) political actor?
2. Is that political actor expressing an issue position?
3. What issue is the actor expressing a position about?
4. What is the polarity of the issue

Note: Step one should be resolvable without extra coding with a combination of keyword search (gazetteering) and some form of co-reference resolution. 

Note2: If we can automatically identify issues that are mentioned in a text (e.g. using the existing CAP models), it might be better to swap step 3 and 2 and ask (“which issue(s) are mentioned in the text”) and (“does actor X express a position about issue Y”). 
