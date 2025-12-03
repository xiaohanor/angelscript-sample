class UBattlefieldHoverboardJumpSettings : UHazeComposableSettings
{
	// How long after falling off edge when you can still jump
	UPROPERTY()
	float JumpGraceTime = 0.2;

	// How long you can buffer input before hitting the ground and activating the jump
	UPROPERTY()
	float JumpBufferTime = 0.13;

	// How much velocity is added along the normal of the ground you are standing on when you jump
	UPROPERTY()
	float JumpImpulse = 1400.0;
}

namespace BattlefieldHoverboardVolumeJumpSettings
{
	const float JumpVolumeImpulse = 2500.0;
}