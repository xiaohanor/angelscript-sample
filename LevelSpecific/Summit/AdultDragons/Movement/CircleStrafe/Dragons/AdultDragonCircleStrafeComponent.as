class UAdultDragonCircleStrafeComponent : UActorComponent
{
	ASummitAdultDragonCircleStrafeManager StrafeManager;
	AHazePlayerCharacter Player;

	bool bSmoothenTransition = false;
	bool bHasReachedEndOfAttackRunSpline = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}
};