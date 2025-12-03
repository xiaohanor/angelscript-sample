class AMeltdownBossPhaseOneVelocityAfterKnockbackActor : AHazeActor
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
		{
			if(Player.IsMio())
				Player.AddMovementImpulse(FVector(-750,-750,0));

			if(Player.IsZoe())
				Player.AddMovementImpulse(FVector(-750,750,0));
		}
	}
};