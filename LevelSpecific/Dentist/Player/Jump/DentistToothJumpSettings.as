class UDentistToothJumpSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Input")
	float JumpInputBufferTime = 0.2;

	UPROPERTY(Category = "Input")
	float JumpGraceTime = 0.2;

	UPROPERTY(Category = "Jump")
	float JumpImpulse = 1400;

	UPROPERTY(Category = "Jump")
	float JumpMaxHorizontalSpeed = 900;

	UPROPERTY(Category = "Chain Jump")
	float ChainJumpGroundGraceTime = 0.2;

	UPROPERTY(Category = "Chain Jump|Double")
	float DoubleJumpImpulseMultiplier = 1.1;

	UPROPERTY(Category = "Chain Jump|Double")
	float DoubleJumpSpinDuration = 0.5;

	UPROPERTY(Category = "Chain Jump|Double")
	float TripleJumpImpulseMultiplier = 1.2;

	UPROPERTY(Category = "Chain Jump|Triple")
	float TripleJumpFlipDuration = 0.7;
};

namespace Dentist
{
	namespace Tags
	{
		const FName Jump = n"Jump";
	}

	namespace Jump
	{
		const bool bApplyRotation = true;
	}
};