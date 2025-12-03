class USanctuaryWellCameraFollowSplineMarkerCapability : UHazeMarkerCapability
{
	//default CapabilityTags.Add(BlockedWhileIn::Swing);
	default CapabilityTags.Add(BlockedWhileIn::Perch);
	default CapabilityTags.Add(BlockedWhileIn::WallRun);

	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnMarkerBlocked()
	{
		Player.BlockCameraFollowSplineRotation(this, 1);
	}

	UFUNCTION(BlueprintOverride)
	void OnMarkerUnblocked()
	{
		Player.UnblockCameraFollowSplineRotation(this, 1);
	}
};