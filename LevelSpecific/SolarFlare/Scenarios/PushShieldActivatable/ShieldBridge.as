class AShieldBridge : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(EditAnywhere)
	TArray<ASolarPanelPowerSlot> PowerSlots; 

	UPROPERTY(EditAnywhere)
	bool bEffectsStartActive = false;

	FVector TargetLocation;

	float MoveSpeed = 1000.0;

	UPROPERTY(EditAnywhere)
	float XTargetOffset = 2000.0;

	int PowerCount;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);

		TargetLocation = ActorLocation + ActorForwardVector * XTargetOffset;

		for (ASolarPanelPowerSlot Slot : PowerSlots)
		{
			Slot.OnSolarPowerSlotActivated.AddUFunction(this, n"OnSolarPowerSlotActivated");
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ActorLocation = Math::VInterpConstantTo(ActorLocation, TargetLocation, DeltaSeconds, XTargetOffset);
	}

	UFUNCTION()
	private void OnSolarPowerSlotActivated()
	{
		PowerCount++;

		if (PowerCount >= PowerSlots.Num())
			ActivateSolarPanel();
	}

	void ActivateSolarPanel()
	{
		SetActorTickEnabled(true);
	}
}