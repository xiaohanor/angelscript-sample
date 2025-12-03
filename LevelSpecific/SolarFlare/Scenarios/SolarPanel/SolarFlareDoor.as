class ASolarFlareDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USolarFlareCoverOverlapComponent CoverComp;

	UPROPERTY(DefaultComponent)
	USolarFlareEffectComponent EffectComp;

	UPROPERTY(EditAnywhere)
	TArray<ASolarPanelPowerSlot> PowerSlots; 

	FVector TargetLocation;

	float MoveSpeed = 1000.0;
	float ZTargetOffset = 1000.0;

	int PowerCount;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);

		TargetLocation = ActorLocation + (FVector::UpVector * ZTargetOffset);
		
		for (ASolarPanelPowerSlot Slot : PowerSlots)
		{
			Slot.OnSolarPowerSlotActivated.AddUFunction(this, n"OnSolarPowerSlotActivated");
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ActorLocation = Math::VInterpConstantTo(ActorLocation, TargetLocation, DeltaSeconds, ZTargetOffset);
	}

	UFUNCTION()
	private void OnSolarPowerSlotActivated()
	{
		PowerCount++;

		if (PowerCount >= PowerSlots.Num())
			ActivateSolarDoor();
	}

	UFUNCTION()
	void ActivateSolarDoor()
	{
		SetActorTickEnabled(true);
	}
}