class UIslandPunchotronSidescrollerGroundMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"GroundMovement");

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 90;

	default DebugCategory = CapabilityTags::Movement;

	EMovementDeltaType RemoteMovementDeltaType = EMovementDeltaType::Native;

	UPathfollowingSettings PathingSettings; 
	UBasicAIMovementSettings MoveSettings;
	UIslandSidescrollerGroundMovementSettings SidescrollerMoveSettings;
	UIslandPunchotronSettings Settings;
	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIDestinationComponent DestinationComp;
	UHazeCrumbSyncedActorPositionComponent CrumbMotionComp;
	UBasicAIAnimationComponent AnimComp;
	UPathfollowingMoveToComponent PathFollowingComp;
	UIslandPunchotronSidescrollerLandingComponent LandingComp;

	UHazeSplineComponent FollowSpline;
	float FollowSplineLocationY;

	USimpleMovementData Movement;

    FVector CustomVelocity;
	FVector PrevLocation;

	// Optional constrain interval
	float MinLocationX;
	float MaxLocationX;
	float ConstrainFriction;
	bool bHasSetConstrainFriction = false;


	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PathingSettings = UPathfollowingSettings::GetSettings(Owner);
		MoveSettings = UBasicAIMovementSettings::GetSettings(Owner);
		Settings = UIslandPunchotronSettings::GetSettings(Owner);
		SidescrollerMoveSettings = UIslandSidescrollerGroundMovementSettings::GetSettings(Owner);		
		ConstrainFriction = Settings.SidescrollerGroundFriction * 3.0;
		DestinationComp = UBasicAIDestinationComponent::GetOrCreate(Owner);		
		CrumbMotionComp = UHazeCrumbSyncedActorPositionComponent::GetOrCreate(Owner); // This has to be created before MoveComp runs BeginPlay
		MoveComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);
		AnimComp = UBasicAIAnimationComponent::GetOrCreate(Owner);
		PathFollowingComp = UPathfollowingMoveToComponent::Get(Owner);
		LandingComp = UIslandPunchotronSidescrollerLandingComponent::Get(Owner);
		Movement = MoveComp.SetupSimpleMovementData();
		UMovementGravitySettings::SetGravityScale(Owner, 6.0, this, EHazeSettingsPriority::Defaults);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{	
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (!Player.IslandIsInSidescrollerMode())
				continue;
			
			UPlayerSplineLockComponent SplineLockComp = UPlayerSplineLockComponent::Get(Player);
			if (SplineLockComp == nullptr)
				continue;

			if (SplineLockComp.InstigatedSettings.Get().Spline != nullptr)
			{
				FollowSpline = SplineLockComp.InstigatedSettings.Get().Spline;
				
				if (FollowSpline == nullptr)
					continue;

				// Store Y-value for snapping to in each update. Assumes spline lies in the XZ-plane.
				float DistAlongSpline = FollowSpline.GetClosestSplineDistanceToWorldLocation(Owner.ActorLocation);
				FSplinePosition FollowSplinePosition = FSplinePosition(FollowSpline, DistAlongSpline, true);
				FollowSplineLocationY = FollowSplinePosition.GetWorldLocation().Y;				
				break;
			}
		}

		if (FollowSpline != nullptr)
		{
			FVector OwnerLoc = Owner.ActorLocation;
			Owner.SetActorLocation( FVector(OwnerLoc.X, FollowSplineLocationY, OwnerLoc.Z) );

			if (SidescrollerMoveSettings.bUseConstrainVolume)
				UpdateMovementBoundaries();					
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FIslandSideScrollerGroundMovementParameters& OutParams) const
	{
		if (FollowSpline == nullptr)
			return false;
		if (DestinationComp.bHasPerformedMovement)
			return false;
		OutParams.Spline = FollowSpline;
        return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (FollowSpline == nullptr)
			return true;
		if (DestinationComp.bHasPerformedMovement)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FIslandSideScrollerGroundMovementParameters Params)
	{	
		FollowSpline = Params.Spline;
		DestinationComp.FollowSpline = FollowSpline;
		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);
		PrevLocation = Owner.ActorLocation;		
		
		float DistAlongSpline = DestinationComp.FollowSpline.GetClosestSplineDistanceToWorldLocation(Owner.ActorLocation);
		DestinationComp.FollowSplinePosition = FSplinePosition(DestinationComp.FollowSpline, DistAlongSpline, true);
		FVector OwnerLoc = Owner.ActorLocation;
		Owner.TeleportActor( FVector(OwnerLoc.X, DestinationComp.FollowSplinePosition.GetWorldLocation().Y, OwnerLoc.Z), Owner.ActorRotation, this);
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(!MoveComp.PrepareMove(Movement))
			return;

		if(HasControl())
		{
			DestinationComp.FollowSpline = FollowSpline;
			ComposeMovement(DeltaTime);
		}
		else
		{
			// Since we normally don't want to replicate velocity, we use move since last frame instead.
			// This can fluctuate wildly, introduce smoothing/velocity replication if necessary
			FVector Velocity = (DeltaTime > 0.0) ? (Owner.ActorLocation - PrevLocation) / DeltaTime : Owner.ActorVelocity;			
			Movement.ApplyCrumbSyncedGroundMovementWithCustomVelocity(Velocity);
			PrevLocation = Owner.ActorLocation;
		}

		MoveComp.ApplyMoveAndRequestLocomotion(Movement, AnimComp.FeatureTag);
		DestinationComp.bHasPerformedMovement = true;
		
		if (HasControl() && MoveComp.NewStateIsOnWalkableGround())
		{
			if (LandingComp.CanTriggerLandingEffect())
			{
				CrumbLanding();
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbLanding()
	{
		UIslandPunchotronEffectHandler::Trigger_OnLanded(Owner, FIslandPunchotronOnLandedParams(0.25));
		LandingComp.UpdateLandingTimestamp();
	}
	
	FVector GetCurrentDestination()
	{
		if (PathingSettings.bIgnorePathfinding)
			return DestinationComp.Destination;

		return PathFollowingComp.GetPathfindingDestination();	
	}

	void ComposeMovement(float DeltaTime)
	{		
		FVector OwnLoc = Owner.ActorLocation;
		FVector Velocity = MoveComp.Velocity;
		Velocity -= CustomVelocity; 

		FVector Destination = GetCurrentDestination();
		FVector HorizontalVelocity = Velocity.ConstrainToPlane(MoveComp.WorldUp);
		FVector VerticalVelocity = Velocity - HorizontalVelocity;		
		float MoveDirSign =	Math::Sign(DestinationComp.FollowSplinePosition.WorldForwardVector.DotProduct(Destination - OwnLoc));
		bool bHasDestination = DestinationComp.HasDestination();
		

		//Debug::DrawDebugSphere(Destination, 60, 12, FLinearColor::Black);
		if (bHasDestination)
		{
			FVector OwnLocHorizontal = OwnLoc;	
			OwnLocHorizontal.Y = Destination.Y;
			OwnLocHorizontal.Z = Destination.Z;

			FVector MoveDirX = (Destination - OwnLoc).GetSafeNormal();
			MoveDirX.Z = 0.0;
			MoveDirX.Y = 0.0;
			
			FHazeAcceleratedVector AccLocation;
			AccLocation.SnapTo(OwnLoc, HorizontalVelocity);
									
			float SlowDownRadiusSqr = Math::Square(100.0);
			float RemainingHorizontalDist = Destination.DistSquared(OwnLocHorizontal);
			float MoveSpeedScale = RemainingHorizontalDist < SlowDownRadiusSqr ? RemainingHorizontalDist / SlowDownRadiusSqr : 1.0;

			// Move towards destination
			float MoveSpeed = DestinationComp.Speed;			

			// Check if moved past boundaries and prevent moving out of volume
			bool bHasMovedPast = false;
			if (SidescrollerMoveSettings.bUseConstrainVolume)
			{
				//float PrevWorldLocationX = PrevFollowSplineLocation.X;
				float PrevWorldLocationX = Owner.ActorLocation.X;
				float WorldLocationX = Owner.ActorLocation.X + MoveDirX.X * MoveSpeed * DeltaTime;

				bool bIsPastMin = WorldLocationX < MinLocationX;
				bool bIsPastMax = WorldLocationX > MaxLocationX;
				if (bIsPastMin)
				{
					bool bIsMovingOutOfVolume = WorldLocationX < PrevWorldLocationX;
					if (bIsMovingOutOfVolume)
						bHasMovedPast = true;
				}
				else if (bIsPastMax)
				{
					bool bIsMovingOutOfVolume = WorldLocationX > PrevWorldLocationX;
					if (bIsMovingOutOfVolume)
						bHasMovedPast = true;
				}
				
				if (bHasMovedPast)
				{
					if (!bHasSetConstrainFriction)
						UIslandPunchotronSettings::SetSidescrollerGroundFriction(Owner, ConstrainFriction, this, EHazeSettingsPriority::Override);
					bHasSetConstrainFriction = true;
					// slow to a stop
					float Friction = Settings.SidescrollerGroundFriction;
					float FrictionFactor = Math::Pow(Math::Exp(-Friction), DeltaTime);

					DestinationComp.ReportStopping();
					HorizontalVelocity *= FrictionFactor;
					Movement.AddHorizontalVelocity(HorizontalVelocity);
				}
				else
				{
					UIslandPunchotronSettings::ClearSidescrollerGroundFriction(Owner, this);
					bHasSetConstrainFriction = false;
					AccLocation.AccelerateTo(OwnLoc + MoveDirX * MoveSpeed * MoveSpeedScale, 2.0, DeltaTime);
					Movement.AddVelocity(AccLocation.Velocity.GetClampedToMaxSize(MoveSpeed));
				}
			}
			else
			{
				AccLocation.AccelerateTo(OwnLoc + MoveDirX * MoveSpeed * MoveSpeedScale, 2.0, DeltaTime);
				Movement.AddVelocity(AccLocation.Velocity.GetClampedToMaxSize(MoveSpeed));
			}
			
			//Debug::DrawDebugArrow(OwnLoc, OwnLoc + AccLocation.Velocity, 20);
			//Debug::DrawDebugArrow(Owner.ActorCenterLocation, Owner.ActorCenterLocation + MoveDirX * 100, 40, bDrawInForeground = true);
			//Movement.AddVelocity(AccLocation.Velocity.GetClampedToMaxSize(MoveSpeed));
		}
		else
		{
			// No destination, slow to a stop
			float Friction = Settings.SidescrollerGroundFriction;
			float FrictionFactor = Math::Pow(Math::Exp(-Friction), DeltaTime);

			DestinationComp.ReportStopping();
			HorizontalVelocity *= FrictionFactor;
			Movement.AddHorizontalVelocity(HorizontalVelocity);
		}

		FVector ConstrainedCustomAcc = DestinationComp.FollowSplinePosition.WorldForwardVector * DestinationComp.CustomAcceleration.DotProduct(DestinationComp.FollowSplinePosition.WorldForwardVector);
		ConstrainedCustomAcc.Z = DestinationComp.CustomAcceleration.Z;
		
		CustomVelocity += ConstrainedCustomAcc * DeltaTime;
		float Friction = MoveComp.IsOnWalkableGround() ? MoveSettings.GroundFriction : MoveSettings.AirFriction;
		CustomVelocity -= CustomVelocity * Friction * DeltaTime;
		// If CustomVelocity needs to be constrained like CustomAcc above, put that here.

		Movement.AddVelocity(CustomVelocity);

		// Turn towards focus?
		if (DestinationComp.Focus.IsValid())
			MoveComp.RotateTowardsDirection(DestinationComp.Focus.GetFocusLocation() - Owner.FocusLocation, MoveSettings.TurnDuration, DeltaTime, Movement);
		// Turn towards destination if still some ways off
		else if (DestinationComp.HasDestination() && !OwnLoc.IsWithinDist(Destination, PathingSettings.AtDestinationRange))
			MoveComp.RotateTowardsDirection(DestinationComp.FollowSplinePosition.WorldForwardVector * MoveDirSign, MoveSettings.TurnDuration, DeltaTime, Movement);
		// Slow to a stop
		else
			MoveComp.StopRotating(MoveSettings.StopTurningDamping, DeltaTime, Movement);

		VerticalVelocity -= VerticalVelocity * Friction * DeltaTime;

		Movement.AddPendingImpulses();
		Movement.AddVelocity(VerticalVelocity);
		Movement.AddGravityAcceleration();
	}

	void UpdateMovementBoundaries()
	{
		TListedActors<AIslandSidescrollerConstrainMovementVolume> ConstrainVolumes = TListedActors<AIslandSidescrollerConstrainMovementVolume>();
		AIslandSidescrollerConstrainMovementVolume CurrentConstrainVolume;
		float BestSqrDist = MAX_flt;
		for (AIslandSidescrollerConstrainMovementVolume Volume : ConstrainVolumes)
		{
			float SqrDist = Volume.ActorLocation.DistSquared(Owner.ActorLocation);
			if (SqrDist < BestSqrDist)
			{
				BestSqrDist = SqrDist;
				CurrentConstrainVolume = Volume;
			}
		}
		check(CurrentConstrainVolume != nullptr, "Could not find a constrain movement volume!");

		MinLocationX = CurrentConstrainVolume.GetMinLocationX();
		MaxLocationX = CurrentConstrainVolume.GetMaxLocationX();
	}
}
