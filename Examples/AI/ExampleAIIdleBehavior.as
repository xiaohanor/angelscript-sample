/**
 * Example idle behavior that just bobs up and down.
 */
class UExampleAIIdleBehavior : UHazeChildCapability
{
	// Can be used either locally or networked
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	float MoveSpeed = 1.0;

	UExampleAIIdleBehavior(float Speed)
	{
		MoveSpeed = Speed;
	}

	// Idle should always be active when it can be according to the behavior tree
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
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
		Owner.ActorLocation = StartPosition;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Wiggle a bit up and down while idle
		Owner.ActorLocation = StartPosition + FVector(0.0, 0.0, 
			Math::Sin(ActiveDuration * MoveSpeed) * 100.0
		);
	}
}