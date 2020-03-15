local jobTypeLocation = 'models.jobTypes.'
return {
  fetch = require(jobTypeLocation .. 'fetch'),
  bluePrint = require(jobTypeLocation .. 'bluePrint'),
  destruct = require(jobTypeLocation .. 'destruct')
}
