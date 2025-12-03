namespace BattlefieldHoverboardAnimParams
{
	const FName HoverboardTrickTriggered = n"HoverboardTrickTriggered";
	const FName HoverboardTrickType = n"HoverboardTrickType";
	const FName HoverboardTrickIndex = n"HoverboardTrickIndex";
	const FName HoverboardReflectedOffWall = n"HoverboardReflectedOffWall";
	const FName HoverboardTrickLandBeforeFinished = n"HoverboardTrickLandBeforeFinished";
	const FName HoverboardTrickFailed = n"HoverboardTrickFailed";
}

namespace BattlefieldHoverboardCapabilityTags
{
	const FName Hoverboard = n"Hoverboard";
	
	const FName HoverboardTrick = n"HoverboardTrick";
	const FName HoverboardTotalScore = n"HoverboardTotalScore";
	const FName HoverboardTrickScore = n"HoverboardTrickScore";
	const FName HoverboardTrickBoost = n"HoverboardTrickBoost";
	const FName HoverboardTrickCameraSettings = n"HoverboardTrickCameraSettings";
}

namespace BattlefieldHoverboardDebugCategory
{
	const FName Hoverboard = n"Hoverboard";
}

namespace BattlefieldHoverboardLocomotionTags
{
	/** Called while in air */
	const FName HoverboardAirMovement = n"HoverboardAirMovement";
	/** Called while grinding */
	const FName HoverboardGrinding = n"HoverboardGrinding";
	/** Called during ground movement */
	const FName Hoverboard = n"Hoverboard";
	/** Called the frame that you land */
	const FName HoverboardLanding = n"HoverboardLanding";

	/** Called when jumping and jumping to grinds */
	const FName HoverboardJumping = n"HoverboardJumping";
}

namespace BattlefieldHoverboardSettings
{
	const bool bGrappleToGrindEnabled = true;
}