# threadsafe_global.gd
# This file is part of Astropolis
# Copyright 2019-2023 Charlie Whitfield, all rights reserved
# *****************************************************************************
extends Node

# Singleton "ThreadsafeGlobal".
#
# This global provides access to threadsafe data. Note that most items here are
# localized to base classes (Interface, NetRef, etc.) for quicker access.


static var tables_aux := {} # derived tables & indexing; see public_preinitializer.gd

