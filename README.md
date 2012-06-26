# Pest, a framework for Probability Estimation

[![Build Status](https://secure.travis-ci.org/kerinin/pest.png)](http://travis-ci.org/kerinin/pest)

**A concise API focused on painless investigation of data sets**

Pest provides a framework for interacting with different probability
estimation models. Pest abstracts common statstical operations including:

* Marginal, Joint and Conditional point probability
* Interval and Cumulative probability
* Entropy, Cross Entropy, and Mutual Information
* Mean, Median, Mode, etc


**Scalability if you need it**

Pest tries to be agnostic about the underlying data data structures, 
so changing libraries (NArray -> Hadoop) is as simple as using a different data source.
Pest is designed to create estimators using subsets of larger data sources, and
transparently constructs estimators to facilitate dynamic querying


**Code structure designed to be extended**

Implementing custom estimation models is easy, and Pest implements some model
common ones for you.


## Install

Add it to your Gemfile and bundle

    gem "pest"

    bundle install 

## API

``` ruby
# Creating Datasets
test = Pest::DataSet::Hash.from_hash hash             # Creates a Hash dataset of observations from a hash
train = Pest::DataSet::NArray.from_hash hash          # Creates a NArray dataset

# DataSet Variables
test.variables                                        # hash of Variable instances detected in observation set
test.v                                                # alias of 'variables'
test.v[:foo]                                          # a specific variable
test.v[:foo] = another_variable                       # explicit declaration

# Creating Estimators
e = Pest::Estimator::Frequency.new(data)              # Frequentist estimator - values treated as unordered set
e = Pest::Estimator::Multinomial.new(data)            # Multinomial estimator
e = Pest::Estimator::Gaussian.new(data)               # Gaussian mean/varaince ML estimator

# Descriptive Statistical Properties
e.mode(:foo)                                          # Mode
e.mean(:foo)                                          # Mean (discrete & continuous only)
e.median(:foo)                                        # Median (discrete & continuous only)
# quantile?
# variance?
# deviation?

# Estimating Entropy (Set & Discrete only)
e.entropy(:foo)                                       # Entropy of 'foo'
e.h(:foo, :bar)                                       # Joint entropy of 'foo' AND 'bar'
e.h(:foo).given(:bar)                                 # Cross entropy of 'foo' : 'bar'
e.mutual_information(:foo, :bar)                      # Mutual information of 'foo' and 'bar'
e.i(:foo, :bar)                                       # Alias

# Estimating Point Probability
e.probability(e.variables[:foo] => 1)                 # Estimate the probability that foo=1
e.p(:foo => 1)                                        # Same as above, tries to find a variable named 'foo'
e.p(:foo => 1, :bar => 2)                             # Estimate the probability that foo=1 AND bar=2
e.p(:foo => 1).given(:bar => 2)                       # Estimate the probability that foo=1 given bar=2
e.p(:foo => 1, :bar => 2).given(:baz => 3, :qux => 4) # Moar

# Batch Point Probability Estimation
e.batch_probability(:foo).in(test)                    # Estimate the probability of each value in test
e.batch_p(:foo, :bar).in(test)                        # Joint probability
e.batch_p(:foo).given(:bar).in(test)                  # Conditional probability
e.batch_p(:foo, :bar).given(:baz, :qux).in(test)      # Moar

# Estimating Cumulative & Interval Probability
e.probability(:foo).greater_than(:bar).in(test)
e.p(:foo).greater_than(:bar).less_than(:baz).in(test)
e.p(:foo).gt(:bar).lt(:baz).given(:qux).in(test)
```
