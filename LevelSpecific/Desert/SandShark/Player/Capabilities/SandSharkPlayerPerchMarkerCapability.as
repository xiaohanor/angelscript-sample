/**
 * A MarkerCapability is a capability that responds to being blocked, instead of the opposite.
 * There's no great way of polling multiple systems on the player, except for getting all different movement components
 * and checking values manually. This way we automatically get notified when we are perching.
 */
class USandSharkPlayerPerchMarkerCapability : UHazeMarkerCapability
{
	default CapabilityTags.Add(BlockedWhileIn::Perch);
	default CapabilityTags.Add(BlockedWhileIn::PerchSpline);

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
		PlayerComp.bIsPerching = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnMarkerUnblocked()
	{
		PlayerComp.bIsPerching = false;
	}
};