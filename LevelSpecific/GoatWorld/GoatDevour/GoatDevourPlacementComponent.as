class UGoatDevourPlacementComponent : USphereComponent
{
	default SphereRadius = 600.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnComponentBeginOverlap.AddUFunction(this, n"EnterTrigger");
		OnComponentEndOverlap.AddUFunction(this, n"ExitTrigger");
	}

	UFUNCTION()
	private void EnterTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		UGoatDevourPlayerComponent DevourComp = UGoatDevourPlayerComponent::Get(Player);
		if (DevourComp == nullptr)
			return;

		DevourComp.CurrentPlacementComp = this;
	}

	UFUNCTION()
	private void ExitTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		UGoatDevourPlayerComponent DevourComp = UGoatDevourPlayerComponent::Get(Player);
		if (DevourComp == nullptr)
			return;

		DevourComp.CurrentPlacementComp = nullptr;
	}
}