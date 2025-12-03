class UBasicAIWallclimbingMovementCapability : UBasicAIMovementCapability
{	
	default CapabilityTags.Add(n"WallclimbingMovement");	

	UWallclimbingComponent WallclimbingComp;
	UWallclimbingPathfollowingSettings WallPathfollowingSettings;
	float OwnerSize = 16.0;

	float LastGroundedTime = 0.0;
	FVector PathNormal = FVector::UpVector;
	USteppingMovementData SteppingMovement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		WallclimbingComp = UWallclimbingComponent::GetOrCreate(Owner);
		WallPathfollowingSettings = UWallclimbingPathfollowingSettings::GetSettings(Owner);

		FVector DummyOrigin;
		FVector Bounds;
		Owner.GetActorBounds(true, DummyOrigin, Bounds, false);
		OwnerSize = Math::Max(Bounds.Y, 16.0);
		SteppingMovement = Cast<USteppingMovementData>(Movement);
	}

	UBaseMovementData SetupMovementData() override
	{
		return MoveComp.SetupSteppingMovementData();
	} 

	bool PrepareMove() override
	{
		return MoveComp.PrepareMove(SteppingMovement, PathNormal);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		PathNormal = -WallclimbingComp.PreferredGravity;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UpdateNormalDirection(DeltaTime, GetCurrentDestination());
		Super::TickActive(DeltaTime);
	}

	void ApplyCrumbSyncedMovement(FVector Velocity) override
	{
		// TODO: Replicate or simulate world up direction
		Movement.ApplyCrumbSyncedGroundMovementWithCustomVelocity(Velocity);			
	}

	bool IsNearFinalDestination(FVector Destination) 
	{
		if (!IsMovingToFinalDestination())
			return false; 
		if (!Pathfinding::IsPathNear(Owner.ActorLocation, Destination, PathingSettings.AtDestinationRange, WallPathfollowingSettings.AtPointHeightTolerance, Owner.ActorUpVector))
			return false;
		return true;
	}

	void UpdateNormalDirection(float DeltaTime, FVector Destination)
	{
		FVector TargetPathNormal = -WallclimbingComp.PreferredGravity;
		if (DestinationComp.HasDestination() && 
			WallclimbingComp.Path.IsValidIndex(PathFollowingComp.PathIndex - 1) && 
			!IsNearFinalDestination(Destination))
		{
			TargetPathNormal = WallclimbingComp.Path[PathFollowingComp.PathIndex - 1].Normal;
			if (WallclimbingComp.Path.IsValidIndex(PathFollowingComp.PathIndex))
			{
				FVector NextPathNormal = WallclimbingComp.Path[PathFollowingComp.PathIndex].Normal;

				float NextDot = PathNormal.DotProduct(NextPathNormal);
				if ((NextDot < 0.9999) && (NextDot > -0.9999))
				{
					float InclineRange = (OwnerSize + 40.0);
					float FromNextDot = NextPathNormal.DotProduct(Owner.ActorLocation - Destination);
					if (FromNextDot < InclineRange)
						TargetPathNormal = NextPathNormal;	
				}
			}
		}
		// At destination, adapt to ground if possible
		else if (MoveComp.HasGroundContact())
		{
			TargetPathNormal = MoveComp.GroundContact.Normal;
		}

		// SlerpTowards does not handle vectors 180 degrees apart
		if (TargetPathNormal.DotProduct(PathNormal) < -0.9999)
			TargetPathNormal = TargetPathNormal + Owner.ActorRightVector * 0.1; 

		PathNormal = PathNormal.SlerpTowards(TargetPathNormal, 2.0 * DeltaTime);
	}

	void ComposeMovement(float DeltaTime) override
	{	
		FVector OwnLoc = Owner.ActorLocation;
		FVector Velocity = MoveComp.Velocity;

		// As we change worldup a lot, we don't switch to air friction immediately
		float Friction = MoveSettings.GroundFriction;
		if (!MoveComp.IsInAir())
			LastGroundedTime = Time::GameTimeSeconds;
		if (Time::GetGameTimeSince(LastGroundedTime) > 0.2)
			Friction = MoveSettings.AirFriction;
		
		FVector Destination = GetCurrentDestination();
		FVector HorizontalVelocity = Velocity.ConstrainToPlane(MoveComp.WorldUp);
		FVector VerticalVelocity = Velocity - HorizontalVelocity;
		FVector MoveDir = (Destination - OwnLoc).GetSafeNormal();

		if (DestinationComp.HasDestination()) 
		{
			float MoveSpeed = DestinationComp.Speed;
			FHazeAcceleratedVector AccLocation;
			AccLocation.SnapTo(OwnLoc, HorizontalVelocity);

			if (IsNearFinalDestination(Destination))
			{
				// Slow to a stop
				AccLocation.AccelerateTo(Destination, 1.0, DeltaTime);
				
				// Keep applying slowed down velocity until we're moving away from destination 
				// TODO: this can be handled better, but will at least stop overshoot sliding on slopes.
				if (MoveDir.DotProduct(HorizontalVelocity) > 0.0) 
				 	Movement.AddVelocity(HorizontalVelocity);

				// MoveTo is completed (note that this will usually mean this capability will deactivate)
				PathFollowingComp.ReportComplete(true);
			}
			else
			{
				// Move towards destination
				AccLocation.AccelerateTo(OwnLoc + MoveDir * MoveSpeed, WallPathfollowingSettings.AccelerationDuration, DeltaTime); 
				Movement.AddVelocity(AccLocation.Velocity.GetClampedToMaxSize(MoveSpeed)); // Hacky clamp but this will be replaced

				if (WallclimbingComp.bDebug) 
				{
					Debug::DrawDebugSphere(Destination, 10, 6, FLinearColor::Green);
					Debug::DrawDebugLine(Owner.ActorLocation, Destination, FLinearColor::Green);
					FVector Origin = Owner.ActorLocation + Owner.ActorUpVector * 100;
					Debug::DrawDebugLine(Origin, Origin + AccLocation.Velocity, FLinearColor::Blue);
				}
			}
		}
		else
		{
			// No destination, slow to a stop
			DestinationComp.ReportStopping();
			HorizontalVelocity -= HorizontalVelocity * Friction * DeltaTime;
			Movement.AddVelocity(HorizontalVelocity);
		}

		CustomVelocity += DestinationComp.CustomAcceleration * DeltaTime;
		CustomVelocity -= CustomVelocity * Friction * DeltaTime;
		Movement.AddVelocity(CustomVelocity);

		// Turn towards focus?
		if (DestinationComp.Focus.IsValid())
			MoveComp.RotateTowardsDirection(DestinationComp.Focus.GetFocusLocation() - Owner.FocusLocation, MoveSettings.TurnDuration, DeltaTime, Movement);
		// Turn towards destination if still some ways off
		else if (DestinationComp.HasDestination() && !Pathfinding::IsPathNear(OwnLoc, Destination, PathingSettings.AtDestinationRange, WallPathfollowingSettings.AtPointHeightTolerance, Owner.ActorUpVector))
			MoveComp.RotateTowardsDirection(MoveDir, MoveSettings.TurnDuration, DeltaTime, Movement);
		// Slow to a stop
		else  
			MoveComp.StopRotating(MoveSettings.StopTurningDamping, DeltaTime, Movement);

		Movement.AddPendingImpulses();
		VerticalVelocity -= VerticalVelocity * Friction * DeltaTime;
		Movement.AddVelocity(VerticalVelocity);
		Movement.AddGravityAcceleration();
	}
}

