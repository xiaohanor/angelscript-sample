struct FDentistLaunchedBallOnLaunchedEventData
{
	UPROPERTY()
	FVector Location;

	UPROPERTY()
	FVector Velocity;
};

struct FDentistLaunchedBallOnImpactEventData
{
	UPROPERTY()
	bool bIsFirstImpact;
	
	UPROPERTY()
	USceneComponent HitComponent;

	UPROPERTY()
	FVector ImpactLocation;

	UPROPERTY()
	FRotator ImpactRotation;

	UPROPERTY()
	float Impulse;
};

struct FDentistLaunchedBallOnHitWaterEventData
{
	UPROPERTY()
	FVector SplashLocation;
};

struct FDentistLaunchedBallOnLaunchPlayerEventData
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

/**
 * Events for the launched balls
 */
UCLASS(Abstract)
class UDentistLaunchedBallEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	ADentistLaunchedBall LaunchedBall;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LaunchedBall = Cast<ADentistLaunchedBall>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunched(FDentistLaunchedBallOnLaunchedEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FDentistLaunchedBallOnImpactEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartRolling() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopRolling() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartFalling() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopFalling() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitWater(FDentistLaunchedBallOnHitWaterEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunchPlayer(FDentistLaunchedBallOnLaunchPlayerEventData EventData) {}
};