struct FMagnetDroneAttractJumpActivateParams
{
	FMagnetDroneTargetData TargetData;
	TArray<UPrimitiveComponent> OverlappingComponents;
}

class UMagnetDroneStartAttractJumpCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default DebugCategory = Drone::DebugCategory;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(MagnetDroneTags::MagnetDroneJump);

	default CapabilityTags.Add(MagnetDroneTags::BlockedWhileAttraction);

	default TickGroup = MagnetDrone::StartAttractTickGroup;
	default TickGroupOrder = MagnetDrone::StartAttractTickGroupOrder;
	default TickGroupSubPlacement = 70;

	UMagnetDroneComponent DroneComp;
	UMagnetDroneAttractJumpComponent AttractJumpComp;
	UMagnetDroneJumpComponent JumpComp;
	UMagnetDroneAttachedComponent AttachedComp;
	UMagnetDroneAttractAimComponent AttractAimComp;
	UMagnetDroneAttractionComponent AttractionComp;

	UHazeMovementComponent MoveComp;
	USweepingMovementData MoveData;

	FVector DetachLocation;
	bool bIsIgnoringDetachOverlaps;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DroneComp = UMagnetDroneComponent::Get(Player);
		AttractJumpComp = UMagnetDroneAttractJumpComponent::Get(Player);
		JumpComp = UMagnetDroneJumpComponent::Get(Player);
		AttachedComp = UMagnetDroneAttachedComponent::Get(Player);
		AttractAimComp = UMagnetDroneAttractAimComponent::Get(Player);
		AttractionComp = UMagnetDroneAttractionComponent::Get(Player);

		MoveComp = UHazeMovementComponent::Get(Player);
		MoveData = MoveComp.SetupSweepingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FMagnetDroneAttractJumpActivateParams& Params) const
	{
		if(!DroneComp.Settings.bAllowJumpingWhileMagneticallyAttached)
			return false;

		if(!DroneComp.Settings.bAttractWhenJumpingFromMagneticSurfaces)
			return false;

		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!AttractJumpComp.JumpAimData.IsValidTarget())
			return false;

		if(AttachedComp.IsAttached())
		{
			if(!JumpComp.WasJumpInputStartedDuringTime(DroneComp.MovementSettings.JumpInputBufferTime))
				return false;

			if(AttachedComp.AttachedData.IsSurface())
			{
				if(!MoveComp.IsOnAnyGround())
					return false;
			}
		}
		else
		{
			if(!AttractionComp.IsInputtingAttract())
				return false;
		}

		Params.TargetData = AttractJumpComp.JumpAimData;

		if(AttachedComp.IsAttachedToSocket() && AttachedComp.AttachedData.GetSocketComp().bIgnoreOverlappingComponentsOnDetach)
			Params.OverlappingComponents = AttachedComp.FindOverlappingComponents();

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.IsOnAnyGround())
			return true;

		if(!AttractionComp.IsAttracting())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FMagnetDroneAttractJumpActivateParams Params)
	{
        Player.BlockCapabilities(MagnetDroneTags::MagnetDroneSocketJump, this);

		JumpComp.ConsumeJumpInput();

		AttachedComp.Detach(n"AttractJump");

		AttractionComp.SetStartAttractTarget(Params.TargetData, EMagnetDroneStartAttractionInstigator::Jump);
		AttractJumpComp.StartJumpAttractFrame = Time::FrameNumber;

		JumpComp.ApplyIsJumping(this);

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
        Player.UnblockCapabilities(MagnetDroneTags::MagnetDroneSocketJump, this);
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
}