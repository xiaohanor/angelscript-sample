namespace BlockedWhileIn
{
	// Core Moves
	const FName AirMotion = n"BlockedWhileInAirMotion";
	const FName FloorMotion = n"BlockedWhileInFloorMotion";
	const FName UnwalkableSlide = n"BlockedWhileInUnwalkableSlide";
	const FName Jump = n"BlockedWhileInJump";
	const FName AirJump = n"BlockedWhileInAirJump";
	const FName Dash = n"BlockedWhileInDash";
	const FName Slide = n"BlockedWhileInSlide";
	const FName WallScramble = n"BlockedWhileInWallScramble";
	const FName WallRun = n"BlockedWhileInWallRun";
	const FName LedgeGrab = n"BlockedWhileInLedgeGrab";
	const FName Sprint = n"BlockedWhileInSprint";
	const FName Strafe = n"BlockedWhileInStrafe";
	const FName Vault = n"BlockedWhileInVault";
	const FName LedgeMantle = n"BlockedWhileInLedgeMantle";
	const FName Skydive = n"BlockedWhileInSkydive";
	const FName HighSpeedLanding = n"BlockedWhileInHighSpeedLanding";

	/**
	 * This tag is blocked while the player is actively 'rolling' during a roll dash.
	 * Some moves want to prevent themselves from activating until the player is upright again, mainly for animation reasons.
	 */
	const FName DashRollState = n"BlockedWhileInDashRollState";
	/**
	 * This tag is blocked during the initial part of rolldashjump until player start to even out pose wise closer to the apex
	 */
	const FName RollDashJumpStart = n"BlockedWhileInRollDashJumpStart";

	// Contextual Moves
	const FName Crouch = n"BlockedWhileInCrouch";
	const FName Swimming = n"BlockedWhileInSwimming";
	const FName Grapple = n"BlockedWhileInGrapple";
	const FName GrappleEnter = n"BlockedWhileInGrappleEnter";
	const FName Ladder = n"BlockedWhileInLadder";
	const FName Swing = n"BlockedWhileInSwing";
	const FName GravityWell = n"BlockedWhileInGravityWell";
	const FName PoleClimb = n"BlockedWhileInPoleClimb";
	const FName Perch = n"BlockedWhileInPerch";
	const FName PerchSpline = n"BlockedWhileInPerchSpline";
	const FName ApexDive = n"BlockedWhileInApexDive";

	// Level Abilities
	const FName ShapeShiftForm = n"BlockedWhileInShapeShiftForm";
}