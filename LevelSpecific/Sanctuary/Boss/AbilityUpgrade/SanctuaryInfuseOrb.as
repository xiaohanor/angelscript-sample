class ASanctuaryInfuseOrb : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent TriggerComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TriggerComp.OnComponentBeginOverlap.AddUFunction(this, n"HandleBeginOverlap");
	}

	UFUNCTION()
	private void HandleBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                                const FHitResult&in SweepResult)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player != nullptr)
		{
			USanctuaryCompanionJumpComponent::GetOrCreate(Player).OrbAquired();
			BP_OnBeginOverlap();
		}
	}

	UFUNCTION(BlueprintEvent)
	private void BP_OnBeginOverlap() {}
};