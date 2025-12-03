class ULightBirdPlayerActivationCapabilty : UHazePlayerCapability
{
	default CapabilityTags.Add(LightBird::Tags::LightBird);
	default BlockExclusionTags.Add(LightBird::Tags::LightBirdActiveDuringIntro);

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 0;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ULightBirdUserComponent UserComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = ULightBirdUserComponent::Get(Owner);
		UserComp.Initialize();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (UserComp.Companion != nullptr)
		{
			UserComp.Companion.RemoveActorDisable(UserComp.ActivationDisabledName);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (UserComp.Companion != nullptr)
		{
			UserComp.Companion.AddActorDisable(UserComp.ActivationDisabledName);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
#if EDITOR		
		//Player.bHazeEditorOnlyDebugBool = true; UserComp.Companion.bHazeEditorOnlyDebugBool = true;
		if (Player.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugString(Player.FocusLocation, "" + UserComp.State);
		}
#endif
	}
}
