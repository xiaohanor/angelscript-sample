// Capability Usage Example
// See http://wiki.hazelight.se/Scripting/Capabilities
// (Control+Click) on links to open

class UExampleCapability : UHazeCapability
{
	/**
	 * Capability tags are used to group capabilities by functionality.
	 * Primarily used for Blocking.
	 */
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"Example");
	
	/**
	 * Capabilities tick at a specific time during the frame.
	 * This can be configured so certain capabilities can activate before others.
	 */
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	UHazeMovementComponent MoveComp;

	/**
	 * Setup() runs at the start of the level, when the capability is first added to the player.
	 * This is normally used to retrieve components from the owner for later usage.
	 */
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	/**
	 * ShouldActivate runs every frame that the capability is deactivated and not blocked.
	 * If this returns true, the capability will immediately be activated.
	 */
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// Activate when the actor is moving fast
		if (MoveComp.Velocity.Size() > 100.0)
			return true;
		// Also activate when the player presses jump
		if (WasActionStarted(ActionNames::MovementJump))
			return true;
		return false;
	}

	/**
	 * ShouldDeactivate runs every frame that the capability is active.
	 * If this returns true, the capability will immediately be deactivated.
	 */
	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// Deactivate when the actor is no longer moving fast
		if (MoveComp.Velocity.Size() < 50.0)
			return true;
		// Deactivate when the player is no longer holding jump
		if (!IsActioning(ActionNames::MovementJump))
			return true;
		return false;
	}

	/**
	 * OnActivated is called as soon as the capability activates.
	 */
	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// By blocking, all capabilities that specify the Movement tag will be deactivated
		Owner.BlockCapabilities(CapabilityTags::Movement, Instigator = this);
		Owner.BlockCapabilities(n"Test", Instigator = this);
	}

	/**
	 * OnDeactivated is called as soon as the capability becomes deactivated for any reason.
	 */
	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// We remove the blocks that we previously added with instigator 'this'
		Owner.UnblockCapabilities(CapabilityTags::Movement, Instigator = this);
		Owner.UnblockCapabilities(n"Test", Instigator = this);
	}

	/**
	 * Every frame that the capability is active, TickActive is executed.
	 */
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}

	/**
	 * PreTick happens every frame, regardless of whether the capability is active, deactivated or blocked.
	 * It runs _before_ ShouldActivate or ShouldDeactivate and any other capability functions.
	 */
	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
	}
};