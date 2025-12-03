class AGiantsSkydiveVelocityGiver : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintCallable)
	void GiveVelocityToPlayer(AHazePlayerCharacter Player)
	{
		Player.SetActorVelocity(Player.MovementWorldUp * -1500);
	}
};