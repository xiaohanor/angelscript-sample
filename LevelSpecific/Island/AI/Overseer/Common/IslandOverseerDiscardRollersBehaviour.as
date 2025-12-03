
class UIslandOverseerDiscardRollersBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	UIslandOverseerSettings Settings;
	UIslandOverseerDeployRollerManagerComponent RollerManager;

	float Duration = 1.83 * 2;
	float AnimDuration = 1.83;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandOverseerSettings::GetSettings(Owner);
		RollerManager = UIslandOverseerDeployRollerManagerComponent::GetOrCreate(Owner);
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
		if(RollerManager.bHidden)
			DeactivateBehaviour();
		AnimComp.RequestFeature(FeatureTagIslandOverseer::RemoveRoller, EBasicBehaviourPriority::Medium, this, AnimDuration);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		// RollerManager.HideRollers();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		
	}
}