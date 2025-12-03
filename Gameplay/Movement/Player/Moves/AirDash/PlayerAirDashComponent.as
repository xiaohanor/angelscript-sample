class UPlayerAirDashComponent : UActorComponent
{
	UPROPERTY()
	UPlayerAirDashSettings Settings;	
	UPROPERTY()
	TSubclassOf<UCameraShakeBase> DashShake;
	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset DashCameraSetting;
	UPROPERTY()
	UForceFeedbackEffect ForceFeedbackAirDash;

	UPROPERTY()
	EAirDashDirection DashDirection;

	AHazePlayerCharacter Player;
	bool bCanAirDash = false;

	private float LastAirDashStartTime = -1.0;
	private float LastAirDashEndTime = -1.0;
	private bool bIsAirDashingInternal = false;

	TArray<FAirDashAutoTarget> AutoTargets;
	TInstigated<FAirDashDirectionConstraint> DirectionConstraint;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = UPlayerAirDashSettings::GetSettings(Cast<AHazeActor>(Owner));
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	void StartDash()
	{
		bIsAirDashingInternal = true;
		LastAirDashStartTime = Time::GameTimeSeconds;
	}

	void StopDash()
	{
		bIsAirDashingInternal = false;
		LastAirDashEndTime = Time::GameTimeSeconds;

	}

	bool IsAirDashing() const
	{
		return bIsAirDashingInternal;
	}

	UFUNCTION()
	void TEMPLaunch()
	{
		Player.AddMovementImpulse(Player.ActorRotation.RotateVector(FVector(1500.0, 0.0, 1500.0)));
	}

	float GetTimeSinceAirDashStarted() const
	{
		return Time::GetGameTimeSince(LastAirDashStartTime);
	}

	float GetTimeSinceAirDashEnded() const
	{
		if (bIsAirDashingInternal)
			return 0.0;
		return Time::GetGameTimeSince(LastAirDashEndTime);
	}

	void AddAutoTarget(FAirDashAutoTarget Target)
	{
		for (int i = AutoTargets.Num() - 1; i >= 0; --i)
		{
			if (AutoTargets[i].Component == Target.Component)
			{
				AutoTargets[i] = Target;
				return;
			}
		}

		AutoTargets.Add(Target);
	}

	void RemoveAutoTarget(USceneComponent Point)
	{
		for (int i = AutoTargets.Num() - 1; i >= 0; --i)
		{
			if (AutoTargets[i].Component == Point)
				AutoTargets.RemoveAtSwap(i);
		}
	}
};

struct FAirDashAutoTarget
{
	USceneComponent Component;
	FVector LocalOffset;

	// NB: Height difference is signed, so being below the target point gives a negative
	bool bCheckHeightDifference = false;
	float MinHeightDifference = 0.0;
	float MaxHeightDifference = 0.0;

	bool bCheckFlatDistance = false;
	float MinFlatDistance = 0.0;
	float MaxFlatDistance = 0.0;

	bool bCheckInputAngle = false;
	float MaxInputAngle = 0.0;

	float MaxShortening = 0.0;
	float ShortenExtraMargin = 0.0;
}

struct FAirDashDirectionConstraint
{
	FVector Direction;
	float MaxAngleRadians = 0.0;
}