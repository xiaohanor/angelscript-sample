
class UBattlefieldHoverboardSwingCancelCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Swing);
	default CapabilityTags.Add(PlayerSwingTags::SwingCancel);

	default DebugCategory = n"Hoverboard";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 18;
	default TickGroupSubPlacement = 20;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;	
	UBattlefieldHoverboardSwingComponent SwingComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Owner);
		SwingComp = UBattlefieldHoverboardSwingComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!WasActionStarted(ActionNames::Cancel))
			return false;

		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!SwingComp.HasActivateSwingPoint())
			return false;

		if (SwingComp.Data.HasValidWall())
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SwingComp.AnimData.State = EPlayerSwingState::Cancel;
		SwingComp.StopSwinging();
	}
}