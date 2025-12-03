struct FTazerBotLaunchParams
{
	FVector Impulse;
	FVector TargetLocation;

	float Time;

	FVector2D RandomTorque;

	void GenerateRandomTorque()
	{
		RandomTorque = FVector2D(Math::RandRange(-4.0, -2.5), Math::RandRange(1.5, 4.0) * (Math::RandRange(0, 1) == 0 ? 1.0 : -1.0));
	}

	bool IsTargetedLaunch() const
	{
		return Time != 0.0;
	}
}

USTRUCT()
struct FTazerBotKnockdownParams
{
	UPROPERTY()
	float Duration = 2.0;

	UPROPERTY()
	float StandUpDuration = 1.0;
}

USTRUCT()
struct FTazerBotTelescopeCollisionData
{
	UPROPERTY()
	UForceFeedbackEffect ForceFeedbackEffect;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShakeClass;
}