;; *******************************************************************
;; gpackage (package manager) for IDL
;;
;; Copyright (C) 2015 Giorgio Calderone
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public icense
;; as published by the Free Software Foundation; either version 2
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.
;;
;; *******************************************************************


;=====================================================================
;NAME:
;  gcompile_file
;
;PURPOSE:
;  This routine provides a replacement for the .COMPILE executive
;  command: it allows to compile a .PRO file within IDL programs.
;
PRO $
   gcompile_file $
   , list ;;IN |Arrays of strings with paths to the file to be compiled
  COMPILE_OPT IDL2
  ON_ERROR, 2

  tmpfile = 'gcompile_file_tmp'

  backup_quiet = !QUIET
  !QUIET = 1
  FOR i=0, N_ELEMENTS(list)-1 DO BEGIN
     ;;PRINT, FORMAT='($, %".")'
     fi = FILE_INFO(list[i])
     IF (~fi.exists) THEN $
        MESSAGE, 'File ' + list[i] + ' does not exists'

     ;SPAWN, 'cat ' + list[i] + ' | perl -pe ''chomp; if (/^function/i) {s/,.*//g; $_.="\n";} else {$_=""} '''
     OPENW, lun, tmpfile + '.pro', /get_lun
     PRINTF, lun, '@' + list[i]
     PRINTF, lun
     PRINTF, lun, 'PRO ' + tmpfile
     PRINTF, lun, 'END'
     FREE_LUN, lun
     RESOLVE_ROUTINE, tmpfile, /EITHER, /COMPILE_FULL_FILE
  ENDFOR
  FILE_DELETE, tmpfile + '.pro', /allow
  ;;PRINT
  !QUIET = backup_quiet
END




;=====================================================================
;NAME:
;  gpackage_require
;
;PURPOSE: 
;
;  Ensure a package has already been correctly compiled and
;  initialized, or issue an error otherwise.  Optionally, it checks
;  for a specific package version (or higher)
;
PRO $
   gpackage_require          $
   , pkgName                 $ ;;IN |String with package name to be checked
   , version                 $ ;;OPT|String with the required package version
   , EXACT_VERSION=exact       ;;KW |Check for the exact version, i.e. even newer versions are not allowed
  COMMON COM_GPACKAGE, compiledPkgName, compiledPkgVers
  COMPILE_OPT IDL2
  ON_ERROR, 2

  IF (N_ELEMENTS(compiledPkgName) EQ 0) THEN $
     MESSAGE, 'No package has been compiled yet.'
 
  iPkg = WHERE(STRUPCASE(compiledPkgName) EQ STRUPCASE(pkgName))
  IF (iPkg[0] EQ -1) THEN $
     MESSAGE, 'Package ' + pkgName + ' has not been compiled yet.'

  IF (N_ELEMENTS(version) EQ 1) THEN BEGIN
     ;;Check for a specific version
     IF (KEYWORD_SET(exact)) THEN BEGIN
        IF (compiledPkgVers[iPkg] NE version) THEN $
           MESSAGE, 'version "' + version + '" of package ' + pkgName + ' is required but available version is "' + compiledPkgVers[iPkg] + '"'
     ENDIF $
     ELSE BEGIN
        IF (compiledPkgVers[iPkg] LT version) THEN $
           MESSAGE, 'version (>=) "' + version + '" of package ' + pkgName + ' is required but available version is "' + compiledPkgVers[iPkg] + '"'
     ENDELSE
  ENDIF
END
