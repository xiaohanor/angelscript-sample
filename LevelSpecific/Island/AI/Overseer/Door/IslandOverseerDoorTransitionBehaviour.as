
class UIslandOverseerDoorTransitionBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	UIslandOverseerSettings Settings;
	AHazeCharacter Character;
	UIslandOverseerDoorComponent DoorComp;
	UIslandOverseerPhaseComponent PhaseComp;
	bool bDoorClosed;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandOverseerSettings::GetSettings(Owner);
		Character = Cast<AHazeCharacter>(Owner);
		DoorComp = UIslandOverseerDoorComponent::Get(Owner);
		PhaseComp = UIslandOverseerPhaseComponent::Get(Owner);
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
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		PhaseComp.SetPhase(EIslandOverseerPhase::DoorCutHead);
	}
}