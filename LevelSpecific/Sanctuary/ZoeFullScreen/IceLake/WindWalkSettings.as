class UWindWalkSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Movement")
	float MaxSpeedMultiplier = 0.6;

    UPROPERTY(Category = "Movement")
	float SlowDownInterpSpeed = 10000.0;

	UPROPERTY(Category = "Movement")
	float AgainstWindMaxSpeed = 100.0;

	UPROPERTY(Category = "Movement")
	float SideWindMaxSpeedMultiplier = 0.3;

	UPROPERTY(Category = "Ground Movement")
	float ForceMultiplier = 100.0;

	UPROPERTY(Category = "Air Movement")
	float ImpulseMultiplier = 15.0;

	UPROPERTY(Category = "Animation")
	float StruggleAccelerationDuration = 0.2;

	UPROPERTY(Category = "Animation")
	float StruggleMoveSpeedMultiplier = 0.005;

	UPROPERTY(Category = "Animation")
	float NoStrugglePlayRate = 0.7;
}

namespace WindWalk
{
    const FName WindWalkTag = n"WindWalk";
    const FName WindWalkImpulseTag = n"WindWalkImpulse";
}