struct FDevCutsceneInputActivationParams
{
	ADevCutscene Cutscene;
}

class UDevCutsceneInputCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(n"SkipCutscene");
	
	default TickGroup = EHazeTickGroup::Input;

	default TickGroupOrder = 100;

	AHazePlayerCharacter PlayerOwner = nullptr;
	UDevCutscenePlayerComponent DevCutsceneComp;

	ADevCutscene LastUsedDevCutscene = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
        PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		DevCutsceneComp = UDevCutscenePlayerComponent::GetOrCreate(PlayerOwner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FDevCutsceneInputActivationParams& ActivationParams) const
	{
		ADevCutscene DevCutscene = DevCutsceneComp.ActiveDevCutscene;
		if (DevCutscene == nullptr)
			return false;

		if (DevCutscene.ProgressionType != EDevCutsceneProgressionType::Input)
			return false;
			
		if (!IsActioning(ActionNames::SkipCutscene))
			return false;

		ActivationParams.Cutscene = DevCutscene;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
    	ADevCutscene DevCutscene = DevCutsceneComp.ActiveDevCutscene;
		if (DevCutscene == nullptr)
			return true;

		if (DevCutscene.ProgressionType != EDevCutsceneProgressionType::Input)
			return true;
			
		if (!IsActioning(ActionNames::SkipCutscene))
			return true;
			
		return false;
	}

    UFUNCTION(BlueprintOverride)
	void OnActivated(FDevCutsceneInputActivationParams ActivationParams)
	{
		LastUsedDevCutscene = ActivationParams.Cutscene;
		LastUsedDevCutscene.SetPlayerWantsToProgress(PlayerOwner.Player, true);
	}

    UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (IsValid(LastUsedDevCutscene))
		{
			LastUsedDevCutscene.SetPlayerWantsToProgress(PlayerOwner.Player, false);
			LastUsedDevCutscene = nullptr;
		}
	}
}