class UTundraPlayerSwingGroundedCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"TundraSwing");
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::LastMovement;

	UTundraPlayerSwingComponent SwingComp;
	UHazeMovementComponent MoveComp;
	USweepingMovementData MoveData;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwingComp = UTundraPlayerSwingComponent::GetOrCreate(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
		MoveData = MoveComp.SetupSweepingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!SwingComp.bIsActive)
			return false;

		if(!MoveComp.HasGroundContact())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!MoveComp.HasGroundContact())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Player.SetActorLocation(SwingComp.HorizontalLocation);
		// Player.MeshOffsetComponent.SetRelativeLocation(FVector::ZeroVector);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			if(WasActionStarted(ActionNames::MovementJump))
			{
				if(Player.IsZoe())
				{
					auto ShapeshiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);
					if(ShapeshiftComp.GetCurrentShapeType() == ETundraShapeshiftShape::Big)
						return;
				}
				Player.AddPlayerLaunchMovementImpulse(FVector::UpVector * 1000);
			}
		}
		else
		{
			SwingComp.UpdateLaunchedOffset(DeltaTime);
		}
	}
};