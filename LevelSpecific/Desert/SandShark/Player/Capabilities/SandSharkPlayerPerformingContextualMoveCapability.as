/**
 * A MarkerCapability is a capability that responds to being blocked, instead of the opposite.
 * There's no great way of polling multiple systems on the player, except for getting all different movement components
 * and checking values manually. This way we automatically get notified when we are in a contextual move.
 */
class USandSharkPlayerPerformingContextualMoveMarkerCapability : UHazeMarkerCapability
{
	default CapabilityTags.Add(BlockedWhileIn::Grapple);
	default CapabilityTags.Add(BlockedWhileIn::GrappleEnter);
	default CapabilityTags.Add(BlockedWhileIn::Ladder);
	default CapabilityTags.Add(BlockedWhileIn::LedgeGrab);
	default CapabilityTags.Add(BlockedWhileIn::LedgeMantle);
	default CapabilityTags.Add(BlockedWhileIn::Perch);
	default CapabilityTags.Add(BlockedWhileIn::PerchSpline);
	default CapabilityTags.Add(BlockedWhileIn::PoleClimb);
	default CapabilityTags.Add(BlockedWhileIn::Swing);
	default CapabilityTags.Add(BlockedWhileIn::Vault);
	default CapabilityTags.Add(BlockedWhileIn::WallRun);
	default CapabilityTags.Add(BlockedWhileIn::WallScramble);

	default TickGroup = EHazeTickGroup::Gameplay;

	USandSharkPlayerComponent PlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = USandSharkPlayerComponent::Get(Owner);
	}
	
	UFUNCTION(BlueprintOverride)
	void OnMarkerBlocked()
	{
		PlayerComp.bIsPerformingContextualMove = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnMarkerUnblocked()
	{
		PlayerComp.bIsPerformingContextualMove = false;
	}
};