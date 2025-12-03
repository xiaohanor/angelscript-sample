class UTundraBossSetupCompoundCapability : UHazeCompoundCapability
{
	default CapabilityTags.Add(n"TundraBossSetupCompound");

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundRunAll()
			.Add(UHazeCompoundSelector()
				.Try(UTundraBossSetupAppearCapability())
				.Try(UTundraBossSetupSmashAttackCapability())
				.Try(UTundraBossSetupWaitCapability())
				.Try(UTundraBossSetupPounceCapability())
				.Try(UTundraBossSetupBreakIceFloorCapability())
			);
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
};