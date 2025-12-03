class USlidingDiscPlayerHydraReactionComponent : UBoxComponent
{
	default BoxExtent = FVector::OneVector * 1000.0;

	UPROPERTY(EditInstanceOnly)
	ESanctuaryHydraPlayerAnimationReaction AnimationReaction;

	bool bTriggered = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnComponentBeginOverlap.AddUFunction(this, n"TriggerBeginOverlap");
		OnComponentEndOverlap.AddUFunction(this, n"TriggerEndOverlap");
	}

	UFUNCTION()
	void TriggerBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		if (bTriggered)
			return;

		ASlidingDisc Disc = Cast<ASlidingDisc>(OtherActor);
		if (Disc == nullptr)
			return;

		bTriggered = true;
		for (auto PlayerComp : Disc.PlayerComponents)
			PlayerComp.HydraPlayerReaction = AnimationReaction;
	}

	UFUNCTION()
	private void TriggerEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		if (!bTriggered)
			return;

		ASlidingDisc Disc = Cast<ASlidingDisc>(OtherActor);
		if (Disc == nullptr)
			return;

		for (auto PlayerComp : Disc.PlayerComponents)
			PlayerComp.HydraPlayerReaction = ESanctuaryHydraPlayerAnimationReaction::None;
	}
}