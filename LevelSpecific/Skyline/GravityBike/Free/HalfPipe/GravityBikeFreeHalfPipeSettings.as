class UGravityBikeFreeHalfPipeSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Back Flip")
	UCurveFloat BackFlipCurve;

	UPROPERTY(Category = "Back Flip")
	UCurveFloat TimeDilationCurve;

	UPROPERTY(Category = "Back Flip|Camera|Follow Absolute")
	float FollowBlendOutTime = 2;
}

namespace GravityBikeFree::HalfPipe
{
	const float AngleThreshold = 50;
	const float MinimumVerticalSpeed = 4000;
	const float TangentMultiplier = 5;
	const float TargetNormalOffset = 200;
	const float BackFlipDuration = 1;
	const bool bNoSlowMoIfNoAmmo = true;
	const float MaxAngleToVertical = 10;
}