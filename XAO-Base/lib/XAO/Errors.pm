package XAO::Errors;
use strict;
use XAO::Utils;

eprint "Got to fix XAO::Errors to be dynamic!!";

package XAO::Errors::Projects;
use strict;
use Error;
use base qw(Error::Simple);

package XAO::Errors::Objects;
use strict;
use Error;
use base qw(Error::Simple);

package XAO::Errors::Base;
use strict;
use Error;
use base qw(Error::Simple);

1;
