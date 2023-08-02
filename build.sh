#!/bin/bash
flutter build apk 
scp build/app/outputs/apk/release/app-release.apk  administrator@192.168.148.103:/home/administrator
ssh -Y administrator@192.168.148.103 mv app-release.apk a.apk 
ssh -Y administrator@192.168.148.103 sudo mv a.apk /var/www/html/
flutter build appbundle
