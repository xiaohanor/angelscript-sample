class AStormFallSetPlayerVelocityManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(5.0));
#endif

	UFUNCTION()
	void ActivatePostTempleSequenceVelocity()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			FVector Velocity = -FVector::UpVector * 2100;
			Player.SetActorVelocity(Velocity);
		}
	}
};