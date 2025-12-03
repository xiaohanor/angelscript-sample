class UIslandRedBlueSlideBlockWeaponCapability : UHazeMarkerCapability
{
	default CapabilityTags.Add(BlockedWhileIn::Slide);

	UIslandRedBlueWeaponUserComponent WeaponUserComp;
	AHazePlayerCharacter Player;

	EIslandRedBlueWeaponHandType CurrentHand;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		WeaponUserComp = UIslandRedBlueWeaponUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnMarkerBlocked()
	{
		CurrentHand = Player.IsMio() ? EIslandRedBlueWeaponHandType::Right : EIslandRedBlueWeaponHandType::Left;
		WeaponUserComp.AddHandBlocker(CurrentHand, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnMarkerUnblocked()
	{
		WeaponUserComp.RemoveHandBlocker(CurrentHand, this);
	}
}