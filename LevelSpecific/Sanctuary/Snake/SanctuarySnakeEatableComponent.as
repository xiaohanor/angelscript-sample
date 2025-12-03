event void FSanctuarySnakeEatableComponentEvent();

class USanctuarySnakeEatableComponent : UActorComponent
{
	UPROPERTY()
	FSanctuarySnakeEatableComponentEvent OnConsumed;

	AHazeActor HazeOwner;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(Owner);
		HazeOwner.JoinTeam(n"SnakeFood");
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		HazeOwner.LeaveTeam(n"SnakeFood");
	}

	void Consume()
	{
		OnConsumed.Broadcast();
	}
}