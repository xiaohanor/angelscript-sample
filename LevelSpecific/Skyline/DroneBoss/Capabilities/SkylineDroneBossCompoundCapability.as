class USkylineDroneBossCompoundCapability : UHazeCompoundCapability
{
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundRunAll()
			.Add(USkylineDroneBossPhaseCapability())
			.Add(USkylineDroneBossLeftAttachCapability())
			.Add(USkylineDroneBossRightAttachCapability())
			.Add(USkylineDroneBossBeamOrbitCapability())
			.Add(USkylineDroneBossHoverCapability())
			.Add(USkylineDroneBossLookAtCapability())
		;
	}
}