
class USkylineTorRearmBehaviour : UBasicBehaviour
{	
	UBasicAIHealthComponent HealthComp;
	USkylineTorHoldHammerComponent HoldHammerComp;
	USkylineTorPhaseComponent PhaseComp;
	USkylineTorSettings Settings;
	UAnimInstanceSkylineTor AnimInstance;

	bool bRecalled;

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
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		bRecalled = false;
		USkylineTorEventHandler::Trigger_OnRearmStart(Owner, FSkylineTorEventHandlerGeneralData(HoldHammerComp.Hammer));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		USkylineTorEventHandler::Trigger_OnRearmStop(Owner, FSkylineTorEventHandlerGeneralData(HoldHammerComp.Hammer));
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ActiveDuration < 10)
			return;

		if(!HoldHammerComp.bDetached)
		{
			PhaseComp.SetState(ESkylineTorState::Aggressive);
			DeactivateBehaviour();
			return;
		}

		if(bRecalled)
			return;
		bRecalled = true;

		if(HoldHammerComp.Hammer.HammerComp.CurrentMode == ESkylineTorHammerMode::Disarmed)
			HoldHammerComp.Hammer.HammerComp.SetMode(ESkylineTorHammerMode::Return);
	}
}