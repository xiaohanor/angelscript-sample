struct FMagnetDroneSocketJumpActivatedParams
{
	FVector JumpDirection;
	float JumpImpulseMultiplier = 1.0;
	TArray<UPrimitiveComponent> OverlappingComponents;
};

class UMagnetDroneSocketJumpCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default DebugCategory = Drone::DebugCategory;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(MagnetDroneTags::MagnetDroneJump);
	default CapabilityTags.Add(MagnetDroneTags::MagnetDroneSocketJump);
	default CapabilityTags.Add(MagnetDroneTags::BlockedWhileInMagnetDroneBounce);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 80;
	default TickGroupSubPlacement = 90;

	UMagnetDroneComponent DroneComp;
	UMagnetDroneAttachedComponent AttachedComp;
	UMagnetDroneJumpComponent JumpComp;
	UMagnetDroneAttractJumpComponent AttractJumpComp;

	UHazeMovementComponent MoveComp;

	FVector DetachLocation;
	bool bIsIgnoringDetachOverlaps;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DroneComp = UMagnetDroneComponent::Get(Player);
		AttachedComp = UMagnetDroneAttachedComponent::Get(Player);
		JumpComp = UMagnetDroneJumpComponent::Get(Player);
		AttractJumpComp = UMagnetDroneAttractJumpComponent::Get(Player);

		MoveComp = UHazeMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FMagnetDroneSocketJumpActivatedParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!DroneComp.Settings.bAllowJumpingWhileMagneticallyAttached)
			return false;

		if(AttachedComp.IsAttachedToSocket())
		{
			if(!AttachedComp.AttachedData.GetSocketComp().bAllowDeattaching)
				return false;
		}

		const bool bInputting = JumpComp.WasJumpInputStartedThisFrame();
		const bool bForceJumpFromSocket = AttachedComp.ForceDetachedFromSocketWithJumpThisOrLastFrame();

		if(!bInputting && !bForceJumpFromSocket)
			return false;

		if(bForceJumpFromSocket)
		{
			Params.JumpDirection = AttachedComp.GetForceDetachJumpDirection();
			Params.JumpImpulseMultiplier = AttachedComp.GetForceDetachJumpImpulseMultiplier();

			if(AttachedComp.GetForceDetachedFromSocketIgnoreOverlappingComponents())
				Params.OverlappingComponents = AttachedComp.FindOverlappingComponents();

			return true;
		}

		if(!AttachedComp.IsAttachedToSocket())
			return false;

		if(AttachedComp.AttachedThisOrLastFrame())
			return false;

		Params.JumpDirection = AttachedComp.AttachedData.GetSocketComp().ForwardVector;
		Params.JumpImpulseMultiplier = 1.0;

		if(AttachedComp.AttachedData.GetSocketComp().bIgnoreOverlappingComponentsOnDetach)
			Params.OverlappingComponents = AttachedComp.FindOverlappingComponents();

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.IsOnWalkableGround())
			return true;

		if(AttachedComp.IsAttached())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FMagnetDroneSocketJumpActivatedParams Params)
	{
		JumpComp.ConsumeJumpInput();

		// Make sure to detach
		if(AttachedComp.IsAttached())
			AttachedComp.Detach(n"SocketJump");

		JumpComp.ApplyIsJumping(this, Params.JumpDirection);
		JumpComp.AddJumpImpulse(this, Params.JumpImpulseMultiplier);

		if(bIsIgnoringDetachOverlaps)
		{
			bIsIgnoringDetachOverlaps = false;
			MoveComp.RemoveMovementIgnoresComponents(GetDetachInstigator());
		}

		if(!Params.OverlappingComponents.IsEmpty())
		{
			bIsIgnoringDetachOverlaps = true;
			DetachLocation = Player.ActorLocation;
			MoveComp.AddMovementIgnoresComponents(GetDetachInstigator(), Params.OverlappingComponents);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		JumpComp.ClearIsJumping(this);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(HasControl() && bIsIgnoringDetachOverlaps)
		{
			if(Player.ActorLocation.Distance(DetachLocation) > MagnetDrone::Radius)
			{
				Crumb_ClearIgnoreDetachOverlappingComponents();
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void Crumb_ClearIgnoreDetachOverlappingComponents()
	{
		bIsIgnoringDetachOverlaps = false;
		MoveComp.RemoveMovementIgnoresComponents(GetDetachInstigator());
	}

	FInstigator GetDetachInstigator() const
	{
		return FInstigator(this, n"Detach");
	}
};