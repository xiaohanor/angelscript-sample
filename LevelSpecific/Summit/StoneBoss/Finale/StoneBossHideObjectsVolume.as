class AStoneBossHideRupturesActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UBillboardComponent Visuals;
	default Visuals.SetWorldScale3D(FVector(5.0));
#endif

	UPROPERTY(EditAnywhere)
	TArray<ACrystalSpikeRuptureManager> RuptureManagers;

	UFUNCTION()
	void ActivateHideRuptures()
	{
		for (ACrystalSpikeRuptureManager Manager : RuptureManagers)
		{
			// Manager.
		}
	}

};