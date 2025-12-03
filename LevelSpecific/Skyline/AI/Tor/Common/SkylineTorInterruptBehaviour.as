class USkylineTorInterruptBehaviour : UBasicBehaviour
{
	USkylineTorDamageComponent DamageComp;
	USkylineTorHoldHammerComponent HoldHammerComp;
	AHazeCharacter Character;
	USkylineTorSettings Settings;
	UAnimInstanceSkylineTor AnimInstance;

	float Duration;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Character = Cast<AHazeCharacter>(Owner);
		DamageComp = USkylineTorDamageComponent::GetOrCreate(Owner);
		HoldHammerComp = USkylineTorHoldHammerComponent::GetOrCreate(Owner);
		AnimInstance = Cast<UAnimInstanceSkylineTor>(Character.Mesh.AnimInstance);
		Duration = AnimInstance.Interrupt.Sequence.PlayLength;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > Duration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AnimComp.RequestFeature(FeatureTagSkylineTor::Disarm, EBasicBehaviourPriority::Medium, this);
		USkylineTorEventHandler::Trigger_OnInterrupt(Owner, FSkylineTorEventHandlerGeneralData(HoldHammerComp.Hammer));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
}