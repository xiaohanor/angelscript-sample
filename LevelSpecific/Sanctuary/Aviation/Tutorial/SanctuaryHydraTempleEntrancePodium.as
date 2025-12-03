class ASanctuaryHydraTempleEntrancePodium : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UGodrayComponent GodRayComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeCapsuleCollisionComponent TriggerComp;

	UPROPERTY(EditAnywhere)
	EHazePlayer PodiumPlayer;

	bool bActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TriggerComp.OnComponentBeginOverlap.AddUFunction(this, n"HandleBeginOverlap");
		TriggerComp.OnComponentEndOverlap.AddUFunction(this, n"HandleEndOverlap");
	}

	UFUNCTION()
	private void HandleBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                                const FHitResult&in SweepResult)
	{
		if (OtherActor == Game::GetPlayer(PodiumPlayer))
			Activate();
	}
	
	UFUNCTION()
	private void HandleEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                              UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		if (OtherActor == Game::GetPlayer(PodiumPlayer))
			Deactivate();
	}

	private void Activate()
	{
		GodRayComp.SetGodrayOpacity(0.2);
		BP_Activate();
		bActive = true;
	}

	private void Deactivate()
	{
		GodRayComp.SetGodrayOpacity(0.07);
		BP_Deactivate();
		bActive = false;
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Activate(){}

	UFUNCTION(BlueprintEvent)
	private void BP_Deactivate(){}
};