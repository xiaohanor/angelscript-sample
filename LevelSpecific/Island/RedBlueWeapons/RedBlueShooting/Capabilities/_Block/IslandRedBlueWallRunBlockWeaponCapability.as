class UIslandRedBlueWallRunBlockWeaponCapability : UHazeMarkerCapability
{
	default CapabilityTags.Add(BlockedWhileIn::WallRun);

	AHazePlayerCharacter Player;
	UIslandRedBlueWeaponUserComponent WeaponUserComp;
	UPlayerWallRunComponent WallRunComp;

	EIslandRedBlueWeaponHandType CurrentHand;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		WeaponUserComp = UIslandRedBlueWeaponUserComponent::Get(Owner);
		WallRunComp = UPlayerWallRunComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnMarkerBlocked()
	{
		CurrentHand = WallRunComp.ActiveData.WallRight.DotProduct(Player.ActorForwardVector) > 0.0 ? EIslandRedBlueWeaponHandType::Right : EIslandRedBlueWeaponHandType::Left;
		WeaponUserComp.AddHandBlocker(CurrentHand, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnMarkerUnblocked()
	{
		WeaponUserComp.RemoveHandBlocker(CurrentHand, this);
	}
}