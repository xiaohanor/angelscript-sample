class ASerpentBossWatchPlayers : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(15.0));
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// FVector BetweenLoc = (Game::Mio.ActorLocation + Game::Zoe.ActorLocation) / 2;
		FVector TargetLoc = Game::Mio.GetCurrentlyUsedCamera().WorldLocation;
		FVector Dir = (TargetLoc - ActorLocation).GetSafeNormal();
		Dir = Dir.ConstrainToPlane(FVector::UpVector);
		ActorRotation = Dir.Rotation();
	}
}