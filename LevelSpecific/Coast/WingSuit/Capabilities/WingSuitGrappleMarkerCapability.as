class UWingSuitGrappleMarkerCapability : UHazeMarkerCapability
{
	default CapabilityTags.Add(BlockedWhileIn::Grapple);

	default TickGroup = EHazeTickGroup::Gameplay;

	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnMarkerBlocked()
	{
		DeactivateWingSuit(Player);
	}
}