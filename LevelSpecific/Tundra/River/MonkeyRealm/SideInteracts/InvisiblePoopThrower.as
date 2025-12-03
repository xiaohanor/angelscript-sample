class AInvisiblePoopThrower : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;

	UPROPERTY(EditAnywhere)
	TSubclassOf<ATundra_River_MonkeyPoop> PoopClass;

	float TimeSincePoop = 0;

	void ThrowPoopAtPlayer(AHazePlayerCharacter Player)
	{
		auto Poop = Cast<ATundra_River_MonkeyPoop>(SpawnActor(PoopClass, ActorLocation));
		Poop.bHomingPoop = true;
		Poop.CalculateTrajectory(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		
	}
};