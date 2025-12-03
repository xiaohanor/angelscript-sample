namespace PlayerMovementTags
{
	const FName CoreMovement = n"CoreMovement";
	const FName ContextualMovement = n"ContextualMovement";
	const FName MovementCameraBehavior = n"MovementCameraBehavior";

	// Core Moves
	const FName AirMotion = n"AirMotion";
	//Any generic movement along ground
	const FName FloorMotion = n"FloorMotion";
	const FName UnwalkableSlide = n"UnwalkableSlide";
	//All variations of jump (Ground/Air/WallRun/etc)
	const FName Jump = n"Jump";
	const FName GroundJump = n"GroundJump";
	const FName AirJump = n"AirJump";
	//All Variations of Dashes (Step/Roll/Air/PerchSpline)
	const FName Dash = n"Dash";
	const FName StepDash = n"StepDash";
	const FName RollDash = n"RollDash";
	const FName AirDash = n"AirDash";
	//All Slide adjacent capabilities (Slide/SlideJump/etc)
	const FName Slide = n"Slide";
	//Any capability related to scrambling up walls
	const FName WallScramble = n"WallScramble";
	//Any capability related to running along walls
	const FName WallRun = n"WallRun";
	const FName LedgeRun = n"LedgeRun";
	const FName LedgeGrab = n"LedgeGrab";
	const FName LedgeMovement = n"LedgeMovement";
	const FName Sprint = n"Sprint";
	const FName Strafe = n"Strafe";
	const FName Vault = n"Vault";
	const FName LedgeMantle = n"LedgeMantle";
	const FName Skydive = n"Skydive";
	//Blanket tag for HighSpeedLanding/ApexDive and its trace capability
	const FName LandingApexDive = n"LandingApexDive";

	// Contextual Moves
	const FName Crouch = n"Crouch";
	const FName Swimming = n"Swimming";
	const FName Grapple = n"Grapple";
	const FName Perch = n"Perch";
	const FName Ladder = n"Ladder";
	const FName Swing = n"Swing";
	const FName GravityWell = n"GravityWell";
	const FName PoleClimb = n"PoleClimb";
	const FName ApexDive = n"ApexDive";
}

namespace PlayerMovementExclusionTags
{
	//Core Moves
	const FName ExcludeAirJumpAndDash = n"ExcludeAirJumpAndDash";

	//ContextualMoves
	const FName ExcludePerch = n"ExcludePerch";
	const FName ExcludePerchFallOff = n"ExcludePerchFallOff";
	const FName ExcludeGrapple = n"ExcludeGrapple";
}