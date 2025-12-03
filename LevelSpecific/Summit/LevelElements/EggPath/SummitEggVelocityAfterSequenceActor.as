class ASummitEggVelocityAfterSequenceActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(10.0));
#endif

	UFUNCTION()
	void AddVelocity()
	{
		for (AHazePlayerCharacter Player : Game::Players)
			Player.AddMovementImpulse(FVector(0,0,-1800.0));
	}
};