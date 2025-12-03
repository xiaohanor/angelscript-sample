class AMoonMarketObjectVolume : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxVolume;
	default BoxVolume.bGenerateOverlapEvents = true;
	default BoxVolume.BoxExtent = FVector(500, 500, 500);

	UPROPERTY(EditInstanceOnly)
	EMoonMarketInteractableTag InteractableTag;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BoxVolume.OnComponentBeginOverlap.AddUFunction(this, n"OnBeginOverlap");
		BoxVolume.OnComponentEndOverlap.AddUFunction(this, n"OnEndOverlap");
	}


	UFUNCTION()
	private void OnBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                            UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                            const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		auto InteractionComp = UMoonMarketPlayerInteractionComponent::Get(Player);
		InteractionComp.ObjectVolumes.Apply(this, this);
	}

	UFUNCTION()
	private void OnEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                          UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

//Prevent lantern disappearing while debug teleporting players
#if EDITOR
		if(UTeleportResponseComponent::GetOrCreate(Player).HasTeleportedSinceLastFrame())
		{
			if(Time::GetGameTimeSince(UPlayerHealthComponent::Get(Player).GameTimeOfDeath) > 3)
				return;
		}
#endif

		auto InteractionComp = UMoonMarketPlayerInteractionComponent::Get(Player);
	
		InteractionComp.ObjectVolumes.Clear(this);
		
		if(InteractionComp.ObjectVolumes.CurrentInstigator == nullptr)
		{
			auto Interactions = InteractionComp.CurrentInteractions;
			for(int i = Interactions.Num() -1; i >= 0; i--)
			{
				if(Interactions[i].InteractableTag == InteractableTag)
				{
					Interactions[i].StopInteraction(Player);
				}
			}
		}
	}
};