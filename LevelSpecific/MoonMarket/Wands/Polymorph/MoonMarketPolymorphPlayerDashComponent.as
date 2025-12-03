
class UMoonMarketPolymorphPlayerDashComponent : UActorComponent
{
	UPROPERTY(NotVisible)
	UMoonMarketPolymorphPlayerDashSettings Settings;	

	UPROPERTY()
	UMoonMarketPolymorphPlayerDashSettings DefaultSettings;

	UPROPERTY()
	FRuntimeFloatCurve SpinSpeedCurve;

	UPROPERTY()
	FRuntimeFloatCurve DashVerticalSpeedCurve;

	UPROPERTY()
	EAirDashDirection DashDirection;

	AHazePlayerCharacter Player;

	private float LastAirDashStartTime = -1.0;
	private float LastAirDashEndTime = -1.0;
	private bool bIsAirDashingInternal = false;

	TInstigated<FAirDashDirectionConstraint> DirectionConstraint;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = UMoonMarketPolymorphPlayerDashSettings::GetSettings(Cast<AHazeActor>(Owner));
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
}