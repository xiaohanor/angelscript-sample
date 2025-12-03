class UMoonMarketPlayerMushroomComponent : UActorComponent
{
	AMushroomPeople Mushroom;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Mushroom = Cast<AMushroomPeople>(Owner);
		Owner.OnActorBeginOverlap.AddUFunction(this, n"OnBeginOverlap");
	}

	UFUNCTION()
	private void OnBeginOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		if(!OtherActor.HasControl())
			return;

		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		if(Player.ActorLocation.Z - Owner.ActorLocation.Z <= 50)
			return;

		if(Player.ActorVelocity.Z >= 0)
			return;

		CrumbBounce(Player);
	}

	UFUNCTION(CrumbFunction)
	void CrumbBounce(AHazePlayerCharacter Player)
	{
		Mushroom.Bounce(Player);
	}
};