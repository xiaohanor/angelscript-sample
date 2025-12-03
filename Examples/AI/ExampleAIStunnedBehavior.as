/**
 * Example stun behavior that animates the AI falling to the floor.
 */
class UExampleAIStunnedBehavior : UHazeChildCapability
{
	// Can be used either locally or networked
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	// Stun should become active
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// The AI is stunned when any player jumps
		for (auto Player : Game::Players)
		{
			if (Player.IsAnyCapabilityActive(n"Jump"))
				return true;
		}
		return false;
	}

	// Stun lasts for 3 seconds
	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return ActiveDuration >= 3.0;
	}

	FVector StartPosition;

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		StartPosition = Owner.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Set the actor back up after stun is over
		Owner.ActorLocation = StartPosition;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Owner.ActorLocation = StartPosition + FVector(
			0.0, 0.0, -500.0 * Math::Min(ActiveDuration, 0.5)
		);
	}
}