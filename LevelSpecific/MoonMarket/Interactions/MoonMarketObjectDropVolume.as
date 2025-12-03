class AMoonMarketObjectDropVolume : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent SphereVolume;
	default SphereVolume.SphereRadius = 500;

	UPROPERTY(EditInstanceOnly)
	EMoonMarketInteractableTag InteractableTag;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SphereVolume.OnComponentBeginOverlap.AddUFunction(this, n"OnBeginOverlap");
		SphereVolume.OnComponentEndOverlap.AddUFunction(this, n"OnEndOverlap");
	}

	UFUNCTION()
	private void OnBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                            UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                            const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		UMoonMarketPlayerInteractionComponent::Get(Player).DropVolume = this;
	}

	UFUNCTION()
	private void OnEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                          UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		UMoonMarketPlayerInteractionComponent::Get(Player).DropVolume = nullptr;
	}
};