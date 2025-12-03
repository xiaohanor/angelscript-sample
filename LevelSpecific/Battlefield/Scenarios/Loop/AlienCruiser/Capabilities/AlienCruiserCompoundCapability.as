class UAlienCruiserCompoundCapability : UHazeCompoundCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundSelector()
			.Try(UHazeCompoundSequence()
				.Then(n"AlienCruiserSpinUpCapability")
				.Then(n"AlienCruiserShootingCapability")
				.Then(n"AlienCruiserSpinDownCapability"))
			.Try(n"AlienCruiserIdleCapability")
			.Try(n"AlienCruiserStopSpinningCapability")
		;
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{

	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// if Dead
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{

	}
}