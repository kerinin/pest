# Pest, a framework for Probability Estimation

[![Build Status](https://secure.travis-ci.org/kerinin/pest.png)](http://travis-ci.org/kerinin/pest)


Pest provides a unified framework for interacting with different probability
estimation models.  

* Pest tries to be agnostic about the underlying data data structures, 
so changing libraries (GSL -> Hadoop) is as simple as using a different data source.
* Pest is designed to create estimators using subsets of larger data sources, and
transparently constructs estimators to facilitate dynamic querying
* Implementing custom estimation models is easy, and Pest implements some model
common ones for you.

Pest abstracts common statstical operations including:

* Marginal, Joint and Conditional point probability
* Interval and Cumulative probability
* Entropy, Cross Entropy, and Mutual Information
* Mean, Median, Mode, etc


## Ruby Install

``` sh
brew install gnuplot  # This may take awhile...
cd /usr/local
git checkout 83ed494 /usr/local/Library/Formula/gsl.rb
brew install gsl      # Forcing gsl v1.4

bundle install 
```

## API

``` ruby
# Creating Datasets
test = Pest::DataSet::Hash.new hash                   # Creates a Hash dataset of observations from a hash
test = Pest::DataSet::Hash.new file                   # Creates a Hash dataset of observations from an IO (Marshalled) 
train = Pest::DataSet::GSL.new file                   # Creates a GSL dataset from and IO instance

# DataSet Variables
test.variables                                        # hash of Variable instances detected in observation set
test.v                                                # alias of 'variables'
test.v[:foo]                                          # a specific variable
test.v[:foo] = another_variable                       # explicit declaration

# Creating Estimators
e = Pest::Estimator::Set::Multinomial.new(test)       # Creates a multinomial estimator for set o
e = Pest::Estimator::Discrete::Gaussian.new(file)     # Creating an estimator with the DataSet API

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
e.probability(o.variables[:foo] => 1)                 # Estimate the probability that foo=1
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

## Working Notes

Do we want variable equality to be name-based?  It may make more sense to allow
variables named differently in different data sets to be equivalent. And how the
fuck do we handle variable type?  I'm almost thinking we don't, and let the actual
estimators take care of type casting
