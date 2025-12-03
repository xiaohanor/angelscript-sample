struct FDentistRotatingRollingObstacleOnLaunchPlayerEventData
{
	UPROPERTY()
	AHazePlayerCharacter Player;

	UPROPERTY()
	float ImpulseStrength;

	UPROPERTY()
	FVector Impulse;
};

UCLASS(Abstract)
class UDentistRotatingRollingObstacleEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	ADentistRotatingRollingObstacle RotatingRollingObstacle;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		RotatingRollingObstacle = Cast<ADentistRotatingRollingObstacle>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunchPlayer(FDentistRotatingRollingObstacleOnLaunchPlayerEventData EventData) {}
};