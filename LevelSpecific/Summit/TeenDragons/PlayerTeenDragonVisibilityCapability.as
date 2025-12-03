class UPlayerTeenDragonVisibilityCapability : UHazeMarkerCapability
{
	default CapabilityTags.Add(CapabilityTags::Visibility);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	AHazePlayerCharacter Player;
	UPlayerTeenDragonComponent DragonComp;

 	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		DragonComp = UPlayerTeenDragonComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnMarkerUnblocked()
	{
		DragonComp.RemoveDragonVisualsBlock(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnMarkerBlocked()
	{
		DragonComp.AddDragonVisualsBlock(this);
	}
};