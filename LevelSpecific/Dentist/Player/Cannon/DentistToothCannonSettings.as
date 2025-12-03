class UDentistToothCannonSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Land")
	float CannonLandDuration = 0.6;

	UPROPERTY(Category = "Roll")
	float CannonLandRollDuration = 0.6;

	UPROPERTY(Category = "Roll")
	float CannonLandRollStopIfInputAfterAlpha = 0.5;

	UPROPERTY(Category = "Roll")
	FRuntimeFloatCurve CannonLandRollAngleAlphaCurve;
};

namespace Dentist::Cannon
{
	const bool bApplyRotation = true;
}