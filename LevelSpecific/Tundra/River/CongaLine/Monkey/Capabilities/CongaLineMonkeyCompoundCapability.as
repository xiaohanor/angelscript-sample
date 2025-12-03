/**
 * A compound capability is a capability with child capabilities
 * It works like a behaviour tree, with the GenerateCompound() sequence being the tree.
 */
class UCongaLineMonkeyCompoundCapability : UHazeCompoundCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CongaLine::Tags::CongaLine);
	
	default TickGroup = EHazeTickGroup::ActionMovement;

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		/**
		 * UHazeCompoundSelector selects a state, the first state that is successful is run, and stops the execution
		 */
		return UHazeCompoundSelector()
			// Run away
			.Try(UHazeCompoundSequence()
				.Then(n"CongaLineMonkeyDisperseCapability")
			)
			// Follow the conga line
			.Try(UHazeCompoundSelector()
				.Try(n"CongaLineMonkeyDanceCapability")
				.Try(n"CongaLineMonkeyEnterCapability")
			)
			// Idle
			.Try(UHazeCompoundRunAll()
				.Add(n"CongaLineMonkeyIdleCapability")
			);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!CongaLine::IsCongaLineActive())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!CongaLine::IsCongaLineActive())
			return true;
		
		return false;
	}
};