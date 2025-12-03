// Capability Networking Example
// See http://wiki.hazelight.se/Scripting/Capabilities/Networking
// (Control+Click) on links to open

/**
 * A simple capability that activates using networking.
 */
class UExampleNetworkCapability : UHazeCapability
{
	// Setting the network mode to crumbed will automatically synchronize activation and deactivations
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	/**
	 * ShouldActivate is only called on the capability's control side.
	 * When the control side returns true, both sides will be activated.
	 */
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// Activate when the player presses jump
		if (WasActionStarted(ActionNames::MovementJump))
			return true;
		return false;
	}

	/**
	 * ShouldDeactivate is only called on the capability's control side.
	 * When the control side returns true, both sides will be deactivated.
	 */
	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Even though only the control side can read input with WasActionStarted,
		// both sides will activate this capability.
		Print("Activated on both sides!");
	}
};
/**
 * Network capabilities can optionally send data in the form of a struct.
 * This data will be the same on both sides when the capability uses crumbs.
 */
struct FExampleNetworkActivationParams
{
	float Strength = 0.0;
};

/**
 * A network capability that sends data into its OnActivated.
 */
class UExampleNetworkParamsCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	float Strength;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FExampleNetworkActivationParams& ActivationParams) const
	{
		if (WasActionStarted(ActionNames::MovementJump))
		{
			// The strength value assigned here will be synced to both sides
			ActivationParams.Strength = 10.0;
			return true;
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FExampleNetworkActivationParams ActivationParams)
	{
		// Will use the same value on both sides
		Strength = ActivationParams.Strength;
		Print("Activated on both sides with strength "+Strength);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Capabilities using Crumb network mode cannot be blocked on the remote side.
		// They will always follow activation and deactivation from the control side.
		// However, if the capability would be blocked on the remote, it becomes _Quiet_ instead but stays active.
		if (!IsQuiet())
		{
			Player.SetFrameForceFeedback(Strength, Strength, Strength, Strength);
		}
	}
};