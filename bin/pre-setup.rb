# This script prevents 'setup.rb' from mucking with the '#!/usr/bin/ruby'
# line in bin/* files when 'ruby setup.rb setup' is run during development.
#
# The script is omitted from tarballs created for distribution; it is only
# present in dev trees obtained via SVN.  Thus, when someone who has obtained
# the package from a distribution tarball (as opposed to obtaining a dev
# version via Subversion) does a 'ruby setup.rb setup' (or 'ruby setup.rb all'),
# 'setup.rb' _will_ go ahead and update their '#!' lines as needed.

set_config('shebang', 'never')
