event void FOnSpiritDragonsCompleted();

class ADarkCaveDragonOrnamentManager : AHazeActor
{
	UPROPERTY()
	FOnSpiritDragonsCompleted OnSpiritDragonsCompleted;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(15));
#endif

	UPROPERTY(EditAnywhere)
	TArray<ADarkCaveDragonOrnament> DragonOrnaments;
	
	int Completed;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (ADarkCaveDragonOrnament Ornament : DragonOrnaments)
		{
			Ornament.OnDarkCaveDragonSpiritFreed.AddUFunction(this, n"OnDarkCaveDragonSpiritFreed");
		}
	}

	UFUNCTION()
	private void OnDarkCaveDragonSpiritFreed()
	{
		Completed++;

		if (Completed >= 4)
		{
			OnSpiritDragonsCompleted.Broadcast();
		}
	}
};