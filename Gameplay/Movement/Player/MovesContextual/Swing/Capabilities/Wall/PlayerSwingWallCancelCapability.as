
class UPlayerSwingWallCancelCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Swing);
	default CapabilityTags.Add(PlayerSwingTags::SwingCancel);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 18;
	default TickGroupSubPlacement = 10;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;	
	UPlayerSwingComponent SwingComp;
	UPlayerWallRunComponent WallRunComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Owner);
		SwingComp = UPlayerSwingComponent::GetOrCreate(Owner);
		WallRunComp = UPlayerWallRunComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSwingWallCancelActivationParams& ActivationParams) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!WasActionStarted(ActionNames::Cancel))
			return false;

		if (!SwingComp.HasActivateSwingPoint())
			return false;

		if (!SwingComp.Data.HasValidWall())
			return false;

		FVector WallVelocity = MoveComp.Velocity.ConstrainToPlane(SwingComp.Data.WallNormal);
		if (WallVelocity.Size() < 400.0)
			ActivationParams.bShouldWallRun = false;
		else
		{
			FPlayerWallRunData WallRunData;
			WallRunData.Component = SwingComp.Data.WallComponent;
			WallRunData.WallRotation = SwingComp.Data.WallRotation;
			WallRunData.Location = SwingComp.Data.WallLocation;
			WallRunData.InitialVelocity = WallVelocity;

			ActivationParams.WallRunData = WallRunData;
			ActivationParams.bShouldWallRun = true;
		}
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSwingWallCancelActivationParams ActivationParams)
	{
		SwingComp.StopSwinging();
		WallRunComp.StartWallRun(ActivationParams.WallRunData);
	}
}

struct FSwingWallCancelActivationParams
{
	bool bShouldWallRun = false;
	FPlayerWallRunData WallRunData;
}