class ASolarPanel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent)
	USolarFlareEffectComponent EffectComp;

	UPROPERTY(DefaultComponent, Attach = Root, ShowOnActor)
	USolarFlarePlayerCoverComponent PlayerCoverComponent;

	UPROPERTY(EditAnywhere)
	int RequiredActivateCount = 1;
	int ActivateCount;

	UPROPERTY(EditAnywhere)
	bool bEffectsStartActive = false;

	FVector TargetLocation;

	float MoveSpeed = 1000.0;
	float ZTargetOffset = 500.0;

	int PowerCount;
	bool bCanBeActive;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TargetLocation = ActorLocation + (FVector::UpVector * ZTargetOffset);

		if (!bEffectsStartActive)
			EffectComp.AddDisabler(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bCanBeActive)
			return;
		
		ActorLocation = Math::VInterpConstantTo(ActorLocation, TargetLocation, DeltaSeconds, ZTargetOffset);
	}

	UFUNCTION()
	void RunActivationCheck()
	{
		ActivateCount++;

		if (ActivateCount >= RequiredActivateCount)
			ActivateSolarPanel();
	}

	private void ActivateSolarPanel()
	{
		EffectComp.RemoveDisabler(this);
		bCanBeActive = true;
	}
}