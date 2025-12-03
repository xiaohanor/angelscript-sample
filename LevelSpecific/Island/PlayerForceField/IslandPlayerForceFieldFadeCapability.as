class UIslandPlayerForceFieldFadeCapability : UHazePlayerCapability
{
	// LastDemotable since it should run after animtions have run so force field pose matches the player's final pose for the frame
	default TickGroup = EHazeTickGroup::LastDemotable;
	default TickGroupOrder = 95;

	UIslandForceFieldComponent ForceField;
	UPlayerHealthComponent HealthComp;
	UIslandPlayerForceFieldUserComponent UserComp;

	const float ForceFieldFadeInDuration = 0.3;
	const float ForceFieldFadeOutDuration = 0.1;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ForceField = UIslandForceFieldComponent::Get(Player);
		UserComp = UIslandPlayerForceFieldUserComponent::Get(Player);
		HealthComp = UPlayerHealthComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!UserComp.bForceFieldActive)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(UserComp.bForceFieldActive)
			return false;

		if(UserComp.ForceFieldFadeAlpha != 0.0)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ForceField.RemoveComponentVisualsBlocker(UserComp);
		UserComp.ForceFieldFadeAlpha = 0.0;
	}
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ForceField.AddComponentVisualsBlocker(UserComp);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float NewAlpha;

		if(UserComp.bForceFieldActive)
			NewAlpha = UserComp.ForceFieldFadeAlpha + DeltaTime / ForceFieldFadeInDuration;
		else
			NewAlpha = UserComp.ForceFieldFadeAlpha - DeltaTime / ForceFieldFadeOutDuration;

		UserComp.ForceFieldFadeAlpha = Math::Clamp(NewAlpha, 0.0, 1.0);

		if(!UserComp.bForceFieldActive)
		{
			ForceField.CopyPoseFromSkeletalComponent(Player.Mesh);
			ForceField.UpdateVisuals(DeltaTime);
		}
	}
}