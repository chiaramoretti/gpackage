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
  COMMON COM_GPACKAGE, compiledPkg
  COMPILE_OPT IDL2
  ON_ERROR, 2

  IF (N_ELEMENTS(compiledPkg) EQ 0) THEN $
     MESSAGE, 'No package has been compiled yet.'
 
  iPkg = WHERE(STRUPCASE(compiledPkg.name) EQ STRUPCASE(pkgName))
  IF (iPkg[0] EQ -1) THEN $
     MESSAGE, 'Package ' + pkgName + ' has not been compiled yet.'

  IF (N_ELEMENTS(version) EQ 1) THEN BEGIN
     avail_vers = compiledPkg[iPkg].vers
     ;;Check for a specific version
     IF (KEYWORD_SET(exact)) THEN BEGIN
        IF (avail_vers NE version) THEN $
           MESSAGE, 'version "' + version + '" of package ' + pkgName + ' is required but available version is "' + avail_vers + '"'
     ENDIF $
     ELSE BEGIN
        IF (avail_vers LT version) THEN $
           MESSAGE, 'version (>=) "' + version + '" of package ' + pkgName + ' is required but available version is "' + avail_vers + '"'
     ENDELSE
  ENDIF
END
