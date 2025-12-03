class ATreasureTempleArenaMagicWaveSpawner : AHazeActor
{
		UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(10.0));
#endif

	UPROPERTY()
	TSubclassOf<ATreasureTempleArenaMagicWave> MagicWaveClass;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
	}
}