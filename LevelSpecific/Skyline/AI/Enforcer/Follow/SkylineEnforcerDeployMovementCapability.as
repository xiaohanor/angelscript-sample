class USkylineEnforcerDeployMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	USkylineEnforcerDeployComponent DeployComp;
	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIDestinationComponent DestinationComp;
	UTeleportingMovementData Movement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DeployComp = USkylineEnforcerDeployComponent::GetOrCreate(Owner);
		DestinationComp = UBasicAIDestinationComponent::GetOrCreate(Owner);
		MoveComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);
		Movement = MoveComp.SetupTeleportingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		if (DestinationComp.bHasPerformedMovement)
			return false;
		if (!DeployComp.bDeploying)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;
		if (DestinationComp.bHasPerformedMovement)
			return true;
		if (!DeployComp.bDeploying)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
			}
			else
			{
				// Follow the crumb trail on the remote side
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Scenario");
			DestinationComp.bHasPerformedMovement = true;
		}
	}
};