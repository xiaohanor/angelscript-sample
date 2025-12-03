class UDentistPlayerSplitToothChaseCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UDentistToothSplitComponent ToothSplitComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ToothSplitComp = UDentistToothSplitComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!ToothSplitComp.bIsSplit)
			return false;

		if(ToothSplitComp.SplitToothAI == nullptr)
			return false;

		if(ToothSplitComp.SplitToothAI.State != EDentistSplitToothAIState::Scared)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!ToothSplitComp.bIsSplit)
			return true;

		if(ToothSplitComp.SplitToothAI == nullptr)
			return true;

		if(ToothSplitComp.SplitToothAI.State != EDentistSplitToothAIState::Scared)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ApplySettings(DentistSplitToothPlayerChaseSettings, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearSettingsByInstigator(this);
	}
};