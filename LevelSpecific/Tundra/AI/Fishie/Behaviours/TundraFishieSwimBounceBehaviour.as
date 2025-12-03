class UTundraFishieSwimBounceBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport  = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UBasicAICharacterMovementComponent MoveComp;
	UTundraFishieComponent FishieComp;
	UTundraFishieSettings Settings;
	float Turntime = -BIG_NUMBER;
	float ValidIntervalStart;
	float ValidIntervalEnd;
	float DirSign; 
	float AvoidForwardObstructionsTime = -BIG_NUMBER;
	float AvoidAboveObstructionsTime = -BIG_NUMBER;
	float AvoidBelowObstructionsTime = -BIG_NUMBER;

	bool bCanUseReturnWaypoint;
	FVector ReturnWaypoint;
	TArray<FVector> ReturnWaypoints;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		FishieComp = UTundraFishieComponent::GetOrCreate(Owner);		
		Settings = UTundraFishieSettings::GetSettings(Owner);
		OnRespawn();
		UHazeActorRespawnableComponent::Get(Owner).OnRespawn.AddUFunction(this, n"OnRespawn");
	}

	UFUNCTION()
	private void OnRespawn()
	{
		FishieComp.StartLoc = Owner.ActorLocation;
		FishieComp.SideDir = Owner.ActorRightVector; // Might want to dig out player side contraint here instead
		FishieComp.Direction = Owner.ActorForwardVector.ConstrainToPlane(FishieComp.SideDir).GetSafeNormal();
		FishieComp.UpDir = FishieComp.Direction.CrossProduct(FishieComp.SideDir);
		ValidIntervalStart = -100.0;
		ValidIntervalEnd = 100.0;
		DirSign = 1.0;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		UBasicAIMovementSettings::SetTurnDuration(Owner, Settings.SwimBounceTurnDuration, this, EHazeSettingsPriority::Gameplay);
		Turntime = -BIG_NUMBER; 
		AvoidForwardObstructionsTime = -BIG_NUMBER;
		AvoidAboveObstructionsTime = -BIG_NUMBER;
		AvoidBelowObstructionsTime = -BIG_NUMBER;

		bCanUseReturnWaypoint = false;
		float ClosestDistSqr = BIG_NUMBER;
		for (FVector Waypoint : ReturnWaypoints)
		{
			float DistSqr = Owner.ActorLocation.DistSquared(Waypoint);
			if (DistSqr > ClosestDistSqr)
				continue;
			// Found a better return waypoint
			bCanUseReturnWaypoint = true;
			ClosestDistSqr = DistSqr;
			ReturnWaypoint = Waypoint;
		}

		UAITundraFishieEventHandler::Trigger_OnStartPatrol(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Owner.ClearSettingsByInstigator(this);

		// Set waypoints to return via when reactivating this behaviour
		ReturnWaypoints.Reset(ReturnWaypoints.Num());
		for (AActor Zone : FishieComp.ActiveHuntingZones)
		{
			auto HuntingZone = Cast<ATundraFishieHuntingZone>(Zone);
			if (HuntingZone == nullptr)
				continue;
			ReturnWaypoints.Append(HuntingZone.ReturnWaypoints);
		}

		UAITundraFishieEventHandler::Trigger_OnStopPatrol(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector FromStart = Owner.ActorLocation - FishieComp.StartLoc;
		float DistAlongDir = FishieComp.Direction.DotProduct(FromStart);
		FVector LocAlongDir = FishieComp.StartLoc + FishieComp.Direction * DistAlongDir;

		AEvergreenRockMovingPlatform ObstructingPlatform = GetObstructingMovingPlatform();
		if (ObstructingPlatform != nullptr)
		{
			// Swim away from view to get around platform
			FVector EscapeDir = ObstructingPlatform.EscapeDirection;
			DestinationComp.MoveTowardsIgnorePathfinding(Owner.ActorLocation + EscapeDir * 100.0, 3000.0);
			DestinationComp.RotateTowards(ReturnWaypoint);
		}
		else if (((DistAlongDir > ValidIntervalStart) && (DistAlongDir < ValidIntervalEnd)) ||
				 (Math::Abs(FishieComp.UpDir.DotProduct(FromStart)) < 50.0))
		{
			// Near path or in valid interval, move along normally
			DestinationComp.MoveTowardsIgnorePathfinding(LocAlongDir + FishieComp.Direction * DirSign * Settings.SwimBounceMoveSpeed, Settings.SwimBounceMoveSpeed);
			
			// Detect valid interval (where we can move normally)
			ValidIntervalStart = Math::Min(ValidIntervalStart, DistAlongDir);
			ValidIntervalEnd = Math::Max(ValidIntervalEnd, DistAlongDir);

			if ((ActiveDuration > Turntime + Settings.SwimBounceTurnCooldown) && MoveComp.HasAnyValidBlockingContacts())
			{
				//FishieComp.Direction = MoveComp.WallImpact.ImpactNormal.ConstrainToPlane(FishieComp.SideDir).GetSafeNormal();
				DirSign *= -1.0;
				Turntime = ActiveDuration;
			}
			DestinationComp.RotateInDirection(FishieComp.Direction * DirSign);

			// We have reached safe positions, never try going through return waypoints after this
			if (ActiveDuration > 1.0)
				bCanUseReturnWaypoint = false;
		}
		else
		{
			// Outside of valid path interval and far from wanted path height. 
			if (bCanUseReturnWaypoint)
			{
				// Return to hunting grounds via waypoint
				DestinationComp.MoveTowardsIgnorePathfinding(ReturnWaypoint, Settings.SwimBounceMoveSpeed);
				DestinationComp.RotateTowards(ReturnWaypoint);
				if ((ActiveDuration > 1.0) && Owner.ActorLocation.IsWithinDist(ReturnWaypoint, 80.0))
					bCanUseReturnWaypoint = false;
			}
			else
			{
				// Avoid obstructions while making our way back
				DirSign = (DistAlongDir > ValidIntervalEnd) ? -1.0 : 1.0;
				UpdateObstructions();
				FVector MoveDir = GetObstacleAvoidanceDirection(DistAlongDir);
				DestinationComp.MoveTowardsIgnorePathfinding(Owner.ActorLocation + MoveDir * Settings.SwimBounceMoveSpeed, Settings.SwimBounceMoveSpeed);
				DestinationComp.RotateInDirection(FishieComp.Direction * DirSign);
			}
		}

		FishieComp.LastMoveLocation = Owner.ActorLocation;

		FishieComp.UpdateEating(AnimComp);
	}

	AEvergreenRockMovingPlatform GetObstructingMovingPlatform()
	{
		if (!MoveComp.HasAnyValidBlockingImpacts())
			return nullptr;
		for (FMovementHitResult Impact : MoveComp.AllImpacts)
		{	
			auto Platform = Cast<AEvergreenRockMovingPlatform>(Impact.Actor);
			if (Platform == nullptr)
				continue;
			if (Owner.ActorLocation.Z > Platform.CollisionCenter.Z)
				continue;
			return Platform;
		}
		return nullptr;
	}

	void UpdateObstructions()
	{
		if (MoveComp.HasImpactedWall() && (MoveComp.WallContact.Normal.DotProduct(FishieComp.Direction * DirSign) < 0.0))
			AvoidForwardObstructionsTime = ActiveDuration + Settings.SwimBounceAvoidObstaclesDuration * 0.25;
		if (MoveComp.HasImpactedCeiling())
			AvoidAboveObstructionsTime = ActiveDuration + Settings.SwimBounceAvoidObstaclesDuration;
		if (MoveComp.HasImpactedGround())
			AvoidBelowObstructionsTime = ActiveDuration + Settings.SwimBounceAvoidObstaclesDuration;
	}

	FVector GetObstacleAvoidanceDirection(float DistAlongDir)
	{
		if (ActiveDuration < AvoidForwardObstructionsTime)
		{
			// Go up if below or down if above
			if (FishieComp.GetPlaneHeight(Owner.ActorLocation) > 0.0)
				return -FVector::UpVector;
			return FVector::UpVector;
		}

		// If hitting ceiling or ground, we move horizontally
		if ((ActiveDuration < AvoidAboveObstructionsTime) || (ActiveDuration < AvoidBelowObstructionsTime))
			return FishieComp.Direction.GetSafeNormal2D() * DirSign;

		// No obstructions, move to nearest end of valid interval
		float IntervalEdge = (DistAlongDir > ValidIntervalEnd) ? ValidIntervalEnd : ValidIntervalStart;
		return ((FishieComp.StartLoc + FishieComp.Direction * IntervalEdge) - Owner.ActorLocation).GetSafeNormal();
	}	
}
