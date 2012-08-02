#!/bin/bash

#Just a quick script to list all managed packages, users, groups, files and services by puppet.
#It does not tell you what exactly is managed,  just that they are managed.

#Check for puppet.conf
PUPCONF="/etc/puppet/puppet.conf"
PUPVAR="/var/lib/puppet"
if [ -r $PUPCONF ]
then
  if grep -q " *vardir[ =]" $PUPCONF
  then
    PUPVAR=$(grep " *vardir[ =]" $PUPCONF | awk -F= '{gsub(" ","",$0); print $NF}')
  fi
fi

PUPYAMLDIR="$PUPVAR/client_yaml/catalog"

if [ -d $PUPYAMLDIR ]
then
  if [ -f $PUPYAMLDIR/$(hostname).yaml ]
  then
    PUPYAML="$PUPYAMLDIR/$(hostname).yaml"
  else
    numfiles="0$(ls -l $PUPYAMLDIR/*.yaml | wc -l)"
    if [ $numfiles -eq 1 ]
    then
      #whatever file is in this directory is the winner
      PUPYAML=$(ls $PUPYAMLDIR/*.yaml)
    else
      #There is more then one file... let's bail for now...
      echo "Unable to find location of client yaml file"
      exit 1
    fi
  fi
else
  echo "Unable to locate puppet yaml file directory"
  exit 1
fi

echo -en "Puppet Managed Resources:\n\n"

awk --posix '
  BEGIN {
    marker=1
    FILEHOLD=0
    PACKAGEHOLD=0
  }
  
  { if ( marker == 1 )
    { if ( $0 ~ "resource_table:" )
      { marker=0
        next
      }
    }

    if ( marker == 0 ) 
    { if ( FILEHOLD == 1 )
      { FILECNT++
        FILES[FILECNT]=$0
        FILEHOLD=0
      }

      if ( PACKAGEHOLD == 1 )
      { PACKAGECNT++
        PACKAGES[PACKAGECNT]=$0
        PACKAGEHOLD=0
      }

      if ( USERHOLD == 1 )
      { USERCNT++
        USER[USERCNT]=$0
        USERHOLD=0
      }

      if ( GROUPHOLD == 1 )
      { GROUPCNT++
        GROUP[GROUPCNT]=$0
        GROUPHOLD=0
      }

      if ( SERVICEHOLD == 1 )
      { SERVICECNT++
        SERVICE[SERVICECNT]=$0
        SERVICEHOLD=0
      }

      if ( $0 ~ "  tags:" )
      { marker=1
      } else {
        if ( $0 ~ /^ *- File/ )
        { FILEHOLD=1
        } 
        if ( $0 ~ /^ *- Package/ )
        { PACKAGEHOLD=1
        }
        if ( $0 ~ /^ *- User$/ )
        { USERHOLD=1
        }
        if ( $0 ~ /^ *- Group/ )
        { GROUPHOLD=1
        }
        if ( $0 ~ /^ *- Service/ )
        { SERVICEHOLD=1
        }
      }
    }
  } END {
    sort = "/bin/sort -k2"
    printf "\033[31mFiles managed by puppet:\033[00m  "
    for ( x = 1; x <= FILECNT; x++ )
    {  printf "\033[35m%s\n\033[00m",FILES[x] | sort
    }
    close(sort)
    printf "\n"
    printf "\033[31mPackages managed by puppet:\033[00m  \n"
    for ( x = 1; x <= PACKAGECNT ; x++ )
    {  printf "\033[35m%s\033[00m\n",PACKAGES[x]
    }
    printf "\n"
    printf "\033[31mServices managed by puppet:\033[00m  \n"
    for ( x = 1; x <= SERVICECNT ; x++ )
    {  printf "\033[35m%s\033[00m\n",SERVICE[x]
    }
    printf "\n"
    printf "\033[31mUsers managed by puppet:\033[00m  \n"
    for ( x = 1; x <= USERCNT ; x++ )
    {  printf "\033[35m%s\033[00m\n",USER[x]
    }
    printf "\n"
    printf "\033[31mGroups managed by puppet:\033[00m  \n"
    for ( x = 1; x <= GROUPCNT ; x++ )
    {  printf "\033[35m%s\033[00m\n",GROUP[x]
    }
    printf "\n"
  }
' $PUPYAML
