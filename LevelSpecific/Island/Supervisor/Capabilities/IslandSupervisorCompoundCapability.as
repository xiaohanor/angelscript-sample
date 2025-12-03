class UIslandSupervisorCompoundCapability : UHazeCompoundCapability
{
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

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundRunAll()
			.Add(UIslandSupervisorPlayerProximityActivateCapability())
			.Add(UHazeCompoundSelector()
				.Try(UIslandSupervisorActiveCapability())
				.Try(
					UHazeCompoundSequence()
						.Then(UIslandSupervisorEnterInactiveCapability())
						.Then(UIslandSupervisorInactiveCapability())
				)
			)
		;
	}
}

class UIslandSupervisorChildCapability : UHazeChildCapability
{
	AIslandSupervisor Supervisor;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Supervisor = Cast<AIslandSupervisor>(Owner);
	}
}