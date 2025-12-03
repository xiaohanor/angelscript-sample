class AMoonMarketKillBalloonVolume : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent Volume;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Volume.OnComponentBeginOverlap.AddUFunction(this, n"OnBeginOverlap");
	}

	UFUNCTION()
	private void OnBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                            UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                            const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		UMoonMarketHoldBalloonComp::Get(Player).PopAllBalloons();
	}
};