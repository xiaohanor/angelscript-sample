
class USkylineTorRecallHammerBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UBasicAIHealthComponent HealthComp;
	USkylineTorHoldHammerComponent HoldHammerComp;
	USkylineTorPhaseComponent PhaseComp;
	USkylineTorSettings Settings;
	UAnimInstanceSkylineTor AnimInstance;
	float Duration;
	bool bReturn;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		HoldHammerComp = USkylineTorHoldHammerComponent::GetOrCreate(Owner);
		PhaseComp = USkylineTorPhaseComponent::GetOrCreate(Owner);
		Settings = USkylineTorSettings::GetSettings(Owner);
		AHazeCharacter Character = Cast<AHazeCharacter>(Owner);
		AnimInstance = Cast<UAnimInstanceSkylineTor>(Character.Mesh.AnimInstance);
		Duration = AnimInstance.RecallHammer.Sequence.PlayLength;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if (!HoldHammerComp.Hammer.HammerComp.bRecall)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Duration)
			return true;
		if (!bReturn && !HoldHammerComp.Hammer.HammerComp.bRecall)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		USkylineTorEventHandler::Trigger_OnRecallHammerStart(Owner, FSkylineTorEventHandlerGeneralData(HoldHammerComp.Hammer));
		AnimComp.RequestFeature(FeatureTagSkylineTor::RecallHammer, EBasicBehaviourPriority::Medium, this);
		bReturn = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		USkylineTorEventHandler::Trigger_OnRecallHammerStop(Owner, FSkylineTorEventHandlerGeneralData(HoldHammerComp.Hammer));
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.RotateTowards(HoldHammerComp.Hammer);

		if(!bReturn && ActiveDuration > Duration * 0.4)
		{
			bReturn = true;
			HoldHammerComp.Hammer.HammerComp.SetMode(ESkylineTorHammerMode::Return);
		}
	}
}