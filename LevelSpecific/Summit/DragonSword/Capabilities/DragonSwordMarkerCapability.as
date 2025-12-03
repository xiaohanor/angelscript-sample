class UDragonSwordMarkerCapability : UHazeMarkerCapability
{
	default CapabilityTags.Add(CapabilityTags::BlockedByCutscene);
	default TickGroup = EHazeTickGroup::LastDemotable;
	default DebugCategory = SummitDebugCapabilityTags::DragonSword;

	AHazePlayerCharacter Player;
	UDragonSwordUserComponent SwordComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SwordComp = UDragonSwordUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnMarkerUnblocked()
	{
		SwordComp.bIsSequenceActive = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnMarkerBlocked()
	{
		SwordComp.bIsSequenceActive = true;
	}
};