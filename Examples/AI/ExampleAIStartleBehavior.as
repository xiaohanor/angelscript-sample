
/**	
 * Example startle capability that quickly vibrates the AI to indicate the player being spotted.
 */
class UExampleAIStartleBehavior : UHazeChildCapability
{
	// Can be used either locally or networked
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	// Startle should always be active when it can be according to the behavior tree
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// The AI becomes startled when any player is within 500 units
		float MinDistance = Math::Min(
			Game::Mio.GetDistanceTo(Owner),
			Game::Zoe.GetDistanceTo(Owner)
		);
		if (MinDistance < 500.0)
			return true;
		return false;
	}

	// Startle lasts a second and then continues on by deactivating
	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return ActiveDuration >= 1.0;
	}

	FVector StartPosition;

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		StartPosition = Owner.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Vibrate quickly during the startle animation
		Owner.ActorLocation = StartPosition + FVector(
			Math::Sin(ActiveDuration * 40.0) * 30.0,
			Math::Sin(ActiveDuration * 40.0) * 30.0,
			0.0
		);
	}
}