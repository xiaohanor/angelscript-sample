
class USkylineTorHammerReturnBehaviour : UBasicBehaviour
{	
	default CapabilityTags.Add(n"Return");

	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UBasicAIHealthComponent HealthComp;
	USkylineTorHammerComponent HammerComp;
	USkylineTorPhaseComponent TorPhaseComp;
	USkylineTorHammerReturnComponent HammerReturnComp;
	USkylineTorSettings Settings;
	FVector StartLocation;
	FHazeAcceleratedRotator AccRotation;
	FHazeAcceleratedVector AccLocation;
	FHazeAcceleratedFloat AccSpeed;
	const float DefaultDuration = 2;
	float Duration;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		HammerComp = USkylineTorHammerComponent::GetOrCreate(Owner);
		HammerReturnComp = USkylineTorHammerReturnComponent::GetOrCreate(Owner);
		TorPhaseComp = USkylineTorPhaseComponent::GetOrCreate(HammerComp.HoldHammerComp.Owner);
		Settings = USkylineTorSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if (HammerComp.HoldHammerComp == nullptr)
			return false; // Streaming out
		if(!HammerComp.HoldHammerComp.bDetached)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if (HammerComp.HoldHammerComp == nullptr)
			return true; // Streaming out
		if(HammerComp.HoldHammerComp.WorldLocation.Distance(Owner.ActorLocation) < 25)
			return true;
		if((HammerComp.HoldHammerComp.WorldLocation - StartLocation).DotProduct(HammerComp.HoldHammerComp.WorldLocation - Owner.ActorLocation) < 0)
			return true;
		if(ActiveDuration > Duration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		StartLocation = Owner.ActorLocation;

		AccLocation.SnapTo(StartLocation);
		AccRotation.SnapTo(Owner.ActorRotation);
		AccSpeed.SnapTo(0);

		const float RecallDistance = HammerComp.HoldHammerComp.WorldLocation.Distance(Owner.ActorLocation);
		USkylineTorHammerEventHandler::Trigger_OnRecallStart(Owner, FSkylineTorHammerOnRecallEventData(RecallDistance));

		Duration = HammerReturnComp.ReturnDurationOverride > SMALL_NUMBER ? HammerReturnComp.ReturnDurationOverride : DefaultDuration;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		if (HammerComp.HoldHammerComp != nullptr) // Can be null when streaming out level e.g. restarting checkpoint
			HammerComp.HoldHammerComp.Attach();
		HammerReturnComp.ReturnDurationOverride = 0;
		USkylineTorHammerEventHandler::Trigger_OnRecallStop(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HammerComp.HoldHammerComp == nullptr)
			return;

		if(HammerReturnComp.ReturnDurationOverride > SMALL_NUMBER)
		{
			AccLocation.AccelerateTo(HammerComp.HoldHammerComp.WorldLocation, HammerReturnComp.ReturnDurationOverride, DeltaTime);
			Owner.ActorLocation = AccLocation.Value;;

			AccRotation.AccelerateTo(HammerComp.HoldHammerComp.WorldRotation, HammerReturnComp.ReturnDurationOverride, DeltaTime);
			Owner.SetActorRotation(AccRotation.Value);
			return;
		}

		FVector Direction = (HammerComp.HoldHammerComp.WorldLocation - Owner.ActorLocation).GetSafeNormal();

		AccSpeed.AccelerateTo(3000, 0.5, DeltaTime);
		Owner.ActorLocation += Direction * DeltaTime * AccSpeed.Value;

		AccRotation.SpringTo(HammerComp.HoldHammerComp.WorldRotation, 250, 0.5, DeltaTime);
		Owner.SetActorRotation(AccRotation.Value);
	}
}