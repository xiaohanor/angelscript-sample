UCLASS(Abstract)
class AAISanctuaryUnseen : ABasicAIGroundMovementCharacter
{
	default CapsuleComponent.GenerateOverlapEvents = true;

	default CapabilityComp.DefaultCapabilities.Remove(n"BasicAIDeathCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryUnseenBehaviourCompoundCapability");

	UPROPERTY(DefaultComponent)
	USanctuaryUnseenChaseComponent ChaseComp;

	UPROPERTY(DefaultComponent, Attach = "MeshOffsetComponent")
	USceneComponent MovementIndicator;
	
	USanctuaryUnseenSettings UnseenSettings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		UnseenSettings = USanctuaryUnseenSettings::GetSettings(this);

		ChaseComp.OnStartChase.AddUFunction(this, n"OnStartChase");
		ChaseComp.OnStopChase.AddUFunction(this, n"OnStopChase");

		ChaseComp.OnStartDarkness.AddUFunction(this, n"OnStartDarkness");
		ChaseComp.OnStopDarkness.AddUFunction(this, n"OnStopDarkness");

		MovementIndicator.SetVisibility(false, true);

			MovementIndicator.SetVisibility(ChaseComp.bChasing, true);
	}

	UFUNCTION()
	private void OnStartDarkness()
	{
		MovementIndicator.SetVisibility(ChaseComp.bChasing, true);
	}

	UFUNCTION()
	private void OnStopDarkness()
	{
		MovementIndicator.SetVisibility(false, true);
	}

	UFUNCTION()
	private void OnStartChase()
	{
		if(ChaseComp.bDarkness)
			MovementIndicator.SetVisibility(true, true);
	}

	UFUNCTION()
	private void OnStopChase()
	{
		if(ChaseComp.bDarkness)
			MovementIndicator.SetVisibility(false, true);
	}
}