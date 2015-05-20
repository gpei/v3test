#!/bin/bash

create_app()
{
  for i in `seq 1 $num`
  do
    osc new-app openshift/ruby-20-rhel7~https://github.com/openshift/ruby-hello-world.git
  done





}
