class UBabyDragonTailClimbCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);	
	default CapabilityTags.Add(n"BabyDragon");
	default CapabilityTags.Add(n"TailClimb");

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 7;
	default TickGroupSubPlacement = 0;

	UPlayerTailBabyDragonComponent DragonComp;
	UPlayerMovementComponent MoveComp;
	UPlayerTargetablesComponent TargetablesComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TargetablesComp = UPlayerTargetablesComponent::Get(Player);
		DragonComp = UPlayerTailBabyDragonComponent::Get(Owner);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DragonComp.ClimbState != ETailBabyDragonClimbState::None)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (DragonComp.ClimbState == ETailBabyDragonClimbState::None)
			return true;
		if (DragonComp.ClimbActivePoint == nullptr)
			return true;
		if (MoveComp.HasMovedThisFrame())
        	return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CapabilityTags::Collision, this);
		Player.BlockCapabilities(n"TailGrab", this);
		Player.BlockCapabilities(n"TailWhip", this);
		Player.BlockCapabilities(n"TailAim", this);
		Player.ApplyCameraSettings(DragonComp.ClimbCameraSettings, 1, this, SubPriority = 100);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DragonComp.ClimbState = ETailBabyDragonClimbState::None;
		DragonComp.ClimbActivePoint = nullptr;

		Player.UnblockCapabilities(CapabilityTags::Collision, this);
		Player.UnblockCapabilities(n"TailGrab", this);
		Player.UnblockCapabilities(n"TailWhip", this);
		Player.UnblockCapabilities(n"TailAim", this);
		Player.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (DragonComp.ClimbState == ETailBabyDragonClimbState::Hang)
		{
			FTransform ActivePointTransform = DragonComp.ClimbActivePoint.GetHangTransform();
			auto PrimaryTarget = TargetablesComp.GetPrimaryTarget(UBabyDragonTailClimbTargetable);

			FRotator WantedRotation;
			if (PrimaryTarget != nullptr)
			{
				FVector WorldDirection = PrimaryTarget.WorldLocation - ActivePointTransform.Location;
				FVector LocalDirection = ActivePointTransform.InverseTransformVector(WorldDirection).GetSafeNormal();
				WantedRotation = FRotator::MakeFromX(LocalDirection);
			}

			DragonComp.AnimationClimbDirection = Math::RInterpConstantTo(DragonComp.AnimationClimbDirection, WantedRotation, DeltaTime, 250.0);
		}
	}
}