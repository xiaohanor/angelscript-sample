class ABattlefieldHoverboardIntroSequenceVelocityManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(5.0));
#endif

	UFUNCTION()
	void ActivatePostIntroSequenceVelocity()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			FVector Velocity = Player.ActorForwardVector * 285;
			Velocity += FVector::UpVector * -2170;
			Player.SetActorVelocity(Velocity);
		}
	}
};