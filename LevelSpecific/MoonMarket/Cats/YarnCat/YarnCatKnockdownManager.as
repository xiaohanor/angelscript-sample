class AYarnCatKnockdownManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(5.0));
#endif

	UPROPERTY(EditInstanceOnly)
	AYarnMoonMarketCat YarnCat;

	UFUNCTION()
	void KnockdownCheck()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			FVector Direction = (Player.ActorLocation - YarnCat.ActorLocation).GetSafeNormal();
			Player.ApplyKnockdown(Direction * 500.0, 3.0);
		}
	}
};