struct FDentistPunchObstacleEventData
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

UCLASS(Abstract)
class UDentistPunchObstacleEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	ADentistPunchObstacle PunchObstacle;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PunchObstacle = Cast<ADentistPunchObstacle>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartPunchingOut() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBounced() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMovingBack() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPunchedPlayer(FDentistPunchObstacleEventData Params) {}
};