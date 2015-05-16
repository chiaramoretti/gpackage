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
;  gpackage
;
;PURPOSE:
;  Explicitly compile a package, i.e. a collection of .pro files
;  within a directory.;
;
;NOTE:
;  The gpackage.pro file should be accessible within the paths listed
;  in the IDL_PATH system variable.  The packages .pro files, on the
;  other hand, should not be accessible: they will be automatically
;  compiled by gpackage.
;
;  A call to gpackage may be placed at the beginning of a
;  function/procedure requiring a specific routine.
;
PRO $
   gpackage                  $
   , pkgPath                 $ ;;IN |String with path to the package ".pro" file containing the package initialization function
   , FORCE_COMPILATION=force $ ;;KW |Force recompilation of the package even if it has laready been compiled
   , RECOMPILE_ALL=recompile $ ;;KW |Re-compile (and re-initialize) all compiled packages
   , _EXTRA=extra              ;;OPT|Keywords passed to the package initialization procedure
  COMMON COM_GPACKAGE, compiledPkg
  COMPILE_OPT IDL2
  ON_ERROR, 2

  ;;Recompilation of all packages
  IF (KEYWORD_SET(recompile)) THEN BEGIN
     FOR iPkg=1, N_ELEMENTS(compiledPkg) -1 DO $
        gpackage, compiledPkg[iPkg].path, /FORCE_COMPILATION, EXTRA=*(compiledPkg[iPkg].extra)
     RETURN
  ENDIF

  ;;Initialize compiledPkg in common block.  First element in the
  ;;array is the structure template
  IF (N_ELEMENTS(compiledPkg) EQ 0) THEN BEGIN
     compiledPkg = { path: '', $
                     name: '', $
                     vers: '', $
                     extra: PTR_NEW() }
  ENDIF     

  ;;Check input parameter
  IF (SIZE(pkgPath, /tname) NE 'STRING') THEN $
     MESSAGE, 'Input parameter is supposed to be a string'

  IF (N_ELEMENTS(pkgPath) NE 1) THEN $
     MESSAGE, 'Input parameter must be a scalar'

  fi = FILE_INFO(pkgPath)
  IF (~fi.exists) THEN $
     MESSAGE, 'File ' + pkgPath + ' does not exists'

  IF (fi.directory) THEN $
     MESSAGE, pkgPath + ' is a directory, while a .pro file was expected'

  IF (STRUPCASE(STRMID(pkgPath, 3, 4, /reverse)) NE '.PRO') THEN $
     MESSAGE, pkgPath + ' is a not a .pro file'

  IF (~KEYWORD_SET(extra)) THEN extra = []

  ;;Extract the absolute path and the package initialization function
  ;;name
  tmp = STRSPLIT(FILE_EXPAND_PATH(pkgPath), '/\', /preserve_null, /extract)
  path = STRJOIN(tmp[0:-2], '/') + '/'
  pkgName = tmp[-1]
  pkgName = STRMID(pkgName, 0, STRLEN(pkgName)-4)

  ;;Check if package has already been compiled
  iPkg = WHERE(compiledPkg.name EQ pkgName)
  IF (iPkg[0] NE -1) THEN BEGIN
     ;;The package has already been compiled. Should we force
     ;;recompilation?
     IF (~KEYWORD_SET(force)) THEN RETURN
  ENDIF

  PRINT, '% Compiling package ' + STRUPCASE(pkgName) + ' in path ' + path

  ;;Compile the package initialization function
  gcompile_file, pkgPath

  ;;Call the package initialization procedure, pass the absolute
  ;;package path and the _EXTRA keywords
  pkgVers = STRING(CALL_FUNCTION(pkgName, path, _EXTRA=extra))

  PRINT, '% Package ' + STRUPCASE(pkgName) + ' (vers. ' + pkgVers + ') has been correctly initialized.'

  ;;Save package info
  IF (iPkg[0] EQ -1) THEN $
     compiledPkg = [compiledPkg, compiledPkg[0]]
  compiledPkg[iPkg].path  = pkgPath
  compiledPkg[iPkg].name  = pkgName
  compiledPkg[iPkg].vers  = pkgVers
  compiledPkg[iPkg].extra = PTR_NEW(extra)


  ;;NOTE: RESOLVE_ALL may fail in detetcting unresolved dependencies if
  ;;the COMPILE_OPT IDL2 directive is not given in each routine.
  backup_quiet = !QUIET
  !QUIET = 1
  RESOLVE_ALL, /CONTINUE_ON_ERROR, UNRESOLVED=unresolved
  !QUIET = backup_quiet
  IF (N_ELEMENTS(unresolved) GT 0) THEN BEGIN
     PRINT
     PRINT, '******************************'
     PRINT, 'These routines are unresolved:'
     FOR i=0, N_ELEMENTS(unresolved)-1 DO $
        PRINT, unresolved[i]
     PRINT, '******************************'
     PRINT
  ENDIF
END
