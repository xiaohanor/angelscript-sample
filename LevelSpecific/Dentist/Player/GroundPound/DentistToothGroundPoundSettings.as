class UDentistToothGroundPoundSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Air")
	int MaxAirGroundPoundCount = 1;

	UPROPERTY(Category = "Anticipation")
	FRuntimeFloatCurve AnticipationHeightAlphaCurve;

	UPROPERTY(Category = "Anticipation")
	float AnticipationHeight = 100;

	UPROPERTY(Category = "Anticipation")
	FRuntimeFloatCurve AnticipationAngleAlphaCurve;

	UPROPERTY(Category = "Anticipation")
	float AnticipationDuration = 0.3;

	UPROPERTY(Category = "Anticipation")
	float AnticipationOffsetResetDuration = 0.1;

	UPROPERTY(Category = "Anticipation")
	float AnticipationBlockDashDuration = 0.3;

	UPROPERTY(Category = "Drop")
	float DropSpeed = 3500;
	
	UPROPERTY(Category = "Drop")
	float DropAcceleration = 12000;

	UPROPERTY(Category = "Bounce")
	float BounceImpulse = 1000;

	UPROPERTY(Category = "Bounce")
	float BounceHorizontalFactor = 0.7;

	UPROPERTY(Category = "Recover")
	float RecoverDuration = 0.5;

	UPROPERTY(Category = "Recover")
	float RecoverIfInputDuration = 0.2;

	UPROPERTY(Category = "Recover")
	FRuntimeFloatCurve RecoverAngleAlphaCurve;

	UPROPERTY(Category = "Recover")
	float RecoverBlockDashDuration = 0.2;

	UPROPERTY(Category = "Crush")
	bool bCrushOtherPlayer = false;
};

namespace Dentist
{
	namespace GroundPound
	{
		const bool bApplyRotation = false;
	}

	namespace Tags
	{
		const FName GroundPound = n"GroundPound";
		const FName BlockedWhileGroundPound = n"BlockedWhileGroundPound";
	}
}