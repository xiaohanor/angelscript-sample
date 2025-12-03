
class USkylineTorMovementCapability : UBasicAIMovementCapability
{	
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"GroundMovement");	

	USkylineTorHoverComponent HoverComp;
	USkylineTorSettings Settings;

	UGroundPathfollowingSettings GroundPathfollowingSettings;
	USteppingMovementData SteppingMovement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USkylineTorSettings::GetSettings(Owner);
		HoverComp = USkylineTorHoverComponent::GetOrCreate(Owner);
		GroundPathfollowingSettings = UGroundPathfollowingSettings::GetSettings(Owner);
		SteppingMovement = Cast<USteppingMovementData>(Movement);
	}

	UBaseMovementData SetupMovementData() override
	{
		return MoveComp.SetupSteppingMovementData();
	} 

	bool PrepareMove() override
	{
		return MoveComp.PrepareMove(SteppingMovement);
	}

	void ApplyCrumbSyncedMovement(FVector Velocity) override
	{
		Movement.ApplyCrumbSyncedGroundMovementWithCustomVelocity(Velocity);			
	}

	void ComposeMovement(float DeltaTime) override
	{	
#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
#endif

		FVector OwnLoc = Owner.ActorLocation;
		FVector Velocity = MoveComp.Velocity;
		Velocity -= CustomVelocity; 

		FVector Destination = GetCurrentDestination();
		FVector HorizontalVelocity = Velocity.ConstrainToPlane(MoveComp.WorldUp);
		FVector VerticalVelocity = Velocity - HorizontalVelocity;
		FVector MoveDir = (Destination - OwnLoc).ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();

#if !RELEASE
		TemporalLog.Sphere("Initial;OwnLoc", OwnLoc, 50, FLinearColor::LucBlue);
		TemporalLog.DirectionalArrow("Initial;Velocity", OwnLoc, Velocity);
		TemporalLog.Sphere("Initial;Destination", Destination, 50, FLinearColor::Green);
		TemporalLog.DirectionalArrow("Initial;HorizontalVelocity", OwnLoc, HorizontalVelocity);
		TemporalLog.DirectionalArrow("Initial;VerticalVelocity", OwnLoc, VerticalVelocity);
		TemporalLog.DirectionalArrow("Initial;MoveDir", OwnLoc, MoveDir);
		TemporalLog.Value("Initial;HasDestination", DestinationComp.HasDestination());
#endif
		
		if (DestinationComp.HasDestination()) 
		{
			float MoveSpeed = DestinationComp.Speed;
			FHazeAcceleratedVector AccLocation;
			AccLocation.SnapTo(OwnLoc, HorizontalVelocity);

#if !RELEASE
			TemporalLog.Value("HasDestination;MoveSpeed", MoveSpeed);
#endif

			if (IsMovingToFinalDestination() && OwnLoc.IsWithinDist(Destination, PathingSettings.AtDestinationRange))
			{
				// Slow to a stop
				AccLocation.AccelerateTo(Destination, 1.0, DeltaTime);
				
				// Keep applying slowed down velocity until we're moving away from destination 
				// TODO: this can be handled better, but will at least stop overshoot sliding on slopes.
				if (MoveDir.DotProduct(HorizontalVelocity) > 0.0) 
					Movement.AddVelocity(HorizontalVelocity);

				// MoveTo is completed (note that this will usually mean this capability will deactivate)
				PathFollowingComp.ReportComplete(true);

#if !RELEASE
				TemporalLog.Status("Slow to a Stop", FLinearColor::Red);
				TemporalLog.Sphere("HasDestination;AccLocation Value", AccLocation.Value, 50);
				TemporalLog.DirectionalArrow("HasDestination;AccLocation Velocity", AccLocation.Value, AccLocation.Velocity);
#endif
			}
			else
			{
				// Less yanky version of Move towards destination:
				// FVector TargetLocation = OwnLoc + MoveDir * MoveSpeed;
				// FPlane DestinationPlane = FPlane(Destination, MoveDir);
				// if(TargetLocation.IsAbovePlane(DestinationPlane))
				// 	TargetLocation = TargetLocation.PointPlaneProject(Destination, MoveDir);

				// AccLocation.AccelerateTo(TargetLocation, GroundPathfollowingSettings.AccelerationDuration, DeltaTime); 
				//const FVector ClampedVelocity = AccLocation.Velocity.GetClampedToMaxSize(MoveSpeed); // Hacky clamp but this will be replaced
				// Movement.AddVelocity(ClampedVelocity);


				// Move towards destination
				AccLocation.AccelerateTo(OwnLoc + MoveDir * MoveSpeed, GroundPathfollowingSettings.AccelerationDuration, DeltaTime);
				const FVector ClampedVelocity = AccLocation.Velocity.GetClampedToMaxSize(MoveSpeed); // Hacky clamp but this will be replaced
				Movement.AddVelocity(ClampedVelocity);
				
#if !RELEASE
				TemporalLog.Status("Move towards destination", FLinearColor::Green);
				TemporalLog.Sphere("HasDestination;AccLocation Value", AccLocation.Value, 50);
				TemporalLog.DirectionalArrow("HasDestination;AccLocation Velocity", AccLocation.Value, AccLocation.Velocity);
				TemporalLog.DirectionalArrow("HasDestination;ClampedVelocity", OwnLoc, ClampedVelocity);
#endif
			}
		}
		else
		{
			// No destination, slow to a stop
			DestinationComp.ReportStopping();
			float Friction = MoveComp.IsInAir() ? MoveSettings.AirFriction : MoveSettings.GroundFriction;
			HorizontalVelocity -= HorizontalVelocity * Friction * DeltaTime;
			Movement.AddVelocity(HorizontalVelocity);

#if !RELEASE
			TemporalLog.Status("No destination, slow to a stop", FLinearColor::Yellow);
#endif
		}

		CustomVelocity += DestinationComp.CustomAcceleration * DeltaTime;
		float Friction = MoveComp.IsOnWalkableGround() ? MoveSettings.GroundFriction : MoveSettings.AirFriction;
		CustomVelocity -= CustomVelocity * Friction * DeltaTime;
		Movement.AddVelocity(CustomVelocity);

#if !RELEASE
		TemporalLog.DirectionalArrow("Final;CustomVelocity", OwnLoc, CustomVelocity);
#endif

		// Turn towards focus?
		if (DestinationComp.Focus.IsValid())
			MoveComp.RotateTowardsDirection(DestinationComp.Focus.GetFocusLocation() - Owner.FocusLocation, MoveSettings.TurnDuration, DeltaTime, Movement);
		// Turn towards destination if still some ways off
		else if (DestinationComp.HasDestination() && !OwnLoc.IsWithinDist(Destination, PathingSettings.AtDestinationRange))
			MoveComp.RotateTowardsDirection(MoveDir, MoveSettings.TurnDuration, DeltaTime, Movement);
		// Slow to a stop
		else  
			MoveComp.StopRotating(MoveSettings.StopTurningDamping, DeltaTime, Movement);

		Movement.AddPendingImpulses();

		VerticalVelocity *= Math::Pow(Math::Exp(-1.5), DeltaTime);
		Movement.AddVelocity(VerticalVelocity);

		if(HoverComp.bHover)
		{
			float HoverAcc = Math::GetMappedRangeValueClamped(FVector2D(Settings.HoverMinHeight, Settings.HoverHeight), FVector2D(4, 0), OwnLoc.Z - ArenaHeight(OwnLoc));
			if(HoverAcc > 0)
				Movement.AddAcceleration(FVector::UpVector * 982 * HoverAcc);
		}

		Movement.AddGravityAcceleration();
	}

	private float ArenaHeight(FVector OwnerLocation)
	{
		FVector HoverLoc = OwnerLocation;

		if(DestinationComp.HasDestination())
			HoverLoc = DestinationComp.Destination;

		FVector MeshLocation;
		if(!Pathfinding::FindNavmeshLocation(HoverLoc, 100, Settings.HoverHeight, MeshLocation))
			return Math::Max(OwnerLocation.Z - Settings.HoverHeight, Math::Min(Game::Mio.ActorLocation.Z, Game::Zoe.ActorLocation.Z)); // TODO: Should use an actor in the arena to determine it's height, rather than players

		return MeshLocation.Z;
	}
}
