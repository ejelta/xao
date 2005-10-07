/* Michael's query:
SELECT puser_0.BRANCH, puser_0.USER_ID, puser_0.NAME, secure_0.SECURITY@2
FROM P21.puser puser_0, P21.secure secure_0
WHERE puser_0.FRECNO = secure_0.FRECNO AND ((secure_0.SECURITY@2>0.0))
*/

DEF VAR d_d as CHAR FORMAT "x(20)" NO-UNDO.

ASSIGN d_d="\001".

FOR EACH p21.puser WHERE puser.user_id NE "" NO-LOCK:
    FIND FIRST p21.secure WHERE secure.frecno = puser.frecno AND secure.security[2] GT 0 NO-LOCK NO-ERROR.
    IF AVAILABLE p21.secure THEN DO:
        PUT UNFORMATTED
	    puser.user_id           d_d
	    puser.branch            d_d
	    puser.name              d_d
        p21.secure.security[2]
        skip
        .
    END.
END.        
