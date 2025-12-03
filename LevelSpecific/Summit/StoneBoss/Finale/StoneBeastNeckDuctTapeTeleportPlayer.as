class AStoneBeastNeckDuctTapeTeleportPlayer : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(5.0));
#endif

	TPerPlayer<FTransform> PlayerTransforms;

	UFUNCTION()
	void SaveLocations()
	{
		for (AHazePlayerCharacter Player : Game::Players)
			PlayerTransforms[Player] = Player.ActorTransform;
	}

	UFUNCTION()
	void SetLocations()
	{
		for (AHazePlayerCharacter Player : Game::Players)
			Player.ActorTransform = PlayerTransforms[Player];
	}
	
};