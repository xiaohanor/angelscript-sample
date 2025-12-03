enum EPlayerLaunchToType
{
	// Launch the player to a specific preset point with an arc, player cannot input movement while this is happening
	LaunchToPoint,
	// Launch the player with a specific velocity in a direction and lock their input for a duration until giving it back
	LaunchWithImpulse,
	// Use a curve to lerp the player to a specific point, leaving them with a set exit velocity
	LerpToPointWithCurve,
}

enum EPlayerLaunchToNetworkMode
{
	// Launch is crumbed
	Crumbed,
	// Simulate the launch locally, but slow down a bit to allow catchup
	SimulateLocal,
	/** 
	 * Simulate the launch locally, but don't slow down.
	 * Allows matching launches between players, but creates a big discrepancy at the end
	 * when it has to go back to the normal crumb trail.
	 */
	SimulateLocalImmediateTrajectory,
}

struct FPlayerLaunchToParameters
{
	// What kind of launch to trajectory to use
	UPROPERTY(EditAnywhere)
	EPlayerLaunchToType Type = EPlayerLaunchToType::LaunchToPoint;

	// How long the launch should take to reach the destination
	UPROPERTY(EditAnywhere)
	float Duration = 1.0;

	//If Type is LaunchToPoint, should we play launch animations
	UPROPERTY(EditAnywhere)
	bool bPlayLaunchAnimations = false;

	// World location to launch to
	UPROPERTY(EditAnywhere, Meta = (EditConditionHides, EditCondition = "Type == EPlayerLaunchToType::LaunchToPoint || Type == EPlayerLaunchToType::LaunchToPointWithCurve"))
	FVector LaunchToLocation;

	// If set, LaunchToLocation is relative to this component
	UPROPERTY(EditAnywhere, Meta = (EditConditionHides, EditCondition = "Type == EPlayerLaunchToType::LaunchToPoint || Type == EPlayerLaunchToType::LaunchToPointWithCurve"))
	USceneComponent LaunchRelativeToComponent = nullptr;

	// Launch impulse to use
	UPROPERTY(EditAnywhere, Meta = (EditConditionHides, EditCondition = "Type == EPlayerLaunchToType::LaunchWithImpulse"))
	FVector LaunchImpulse;

	// Whether to rotate or not
	UPROPERTY(EditAnywhere)
	bool bRotate = true;

	// Launch curve to use. If not specified, a standard smooth curve is used
	UPROPERTY(EditAnywhere, Meta = (EditConditionHides, EditCondition = "Type == EPlayerLaunchToType::LaunchToPointWithCurve"))
	UCurveFloat LaunchCurve = nullptr;

	// Exit velocity after the launch is over. If unset, the velocity at the end of the launch is used
	UPROPERTY(EditAnywhere)
	TOptional<FVector> ExitVelocity;

	/**
	 * Whether the launch should be simulated locally on the remote side.
	 * This can make it appear more responsive, but also leads to potential rubberbanding.
	 */
	UPROPERTY(EditAnywhere, AdvancedDisplay)
	EPlayerLaunchToNetworkMode NetworkMode = EPlayerLaunchToNetworkMode::Crumbed;

	bool ShouldHaveCollision() const
	{
		switch (Type)
		{
			case EPlayerLaunchToType::LaunchToPoint:
			case EPlayerLaunchToType::LerpToPointWithCurve:
				return false;
			case EPlayerLaunchToType::LaunchWithImpulse:
				return true;
		}
	}

	FVector GetWorldTargetLocation() const
	{
		if (LaunchRelativeToComponent == nullptr)
			return LaunchToLocation;
		else
			return LaunchRelativeToComponent.WorldTransform.TransformPosition(LaunchToLocation);
	}
}

class UPlayerLaunchToComponent : UActorComponent
{
	bool bHasPendingLaunchTo = false;
	FInstigator PendingLaunchToInstigator;
	FPlayerLaunchToParameters PendingLaunchTo;
};