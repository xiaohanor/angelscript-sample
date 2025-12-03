class USanctuaryDarkPortalCompanionObstructedReturnCapability : UHazeCapability
{
	default CapabilityTags.Add(BasicAITags::Behaviour);
	default CapabilityTags.Add(DarkPortal::Tags::DarkPortal);
	default CapabilityTags.Add(n"ObstructionAvoidance");
	default CapabilityTags.Add(n"BlockedDuringIntro");	

	default TickGroup = EHazeTickGroup::BeforeMovement; 
	default TickGroupOrder = 120; // Always let non-free flying capabilities get their chance first

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USanctuaryDarkPortalCompanionComponent CompanionComp;
	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIAnimationComponent AnimComp; 
	USanctuaryDarkPortalCompanionSettings Settings;
	UTeleportingMovementData Movement;

	FVector Destination;

	FHazeRuntimeSpline Spline;

	FHazeAcceleratedFloat Speed;
	float CurrentDistance;

	bool bHasLOS = true;
	float CheckLOSTime = 0.0;
	float ObstructionDuration = 0.0;
	float UnobstructedDuration = 0.0;

	UTargetTrailComponent PlayerTrailComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CompanionComp = USanctuaryDarkPortalCompanionComponent::GetOrCreate(Owner); 
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner); 
		Settings = USanctuaryDarkPortalCompanionSettings::GetSettings(Owner); 
		Movement = MoveComp.SetupTeleportingMovementData();

		UTargetTrailComponent::GetOrCreate(Game::Zoe);
		UTargetTrailComponent::GetOrCreate(Game::Mio);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (IsBlocked() || !CompanionComp.IsFreeFlying() || CompanionComp.Player.IsPlayerDead())
		{
			ResetObstructed();
			return;
		}
		
		if (IsActive())
		{
			// Check if no longer obstructed 
			if (IsObstructed(0.5))
				UnobstructedDuration = 0.0;
			else 
				UnobstructedDuration += DeltaTime;
		}
		else
		{
			// Check if obstructed
			if (IsObstructed(0.2))
				ObstructionDuration += DeltaTime;
			else
				ObstructionDuration = 0.0;

			if (ObstructionDuration > Settings.ObstructedDetectDuration)
				CompanionComp.State = EDarkPortalCompanionState::Obstructed; // Set this here to deactivate follow etc
		}
	}

	void ResetObstructed()
	{
		ObstructionDuration = 0.0;
		if (CompanionComp.State == EDarkPortalCompanionState::Obstructed)
			CompanionComp.State = EDarkPortalCompanionState::Follow;	
	}

	bool IsObstructed(float LOSInterval)
	{
		if (CompanionComp.Player.bIsControlledByCutscene)
			return false;
		if (!SceneView::IsInView(CompanionComp.Player, Owner.ActorLocation))
			return true;
		if (MoveComp.HasAnyValidBlockingContacts())
			return true;
		if (Time::GameTimeSeconds > CheckLOSTime)
		{
			// Check if visible from camera. We trace from camera to bird in case bird is inside 
			// something which does not block trace from it's back side.
			FHazeTraceSettings Trace = Trace::InitChannel(ETraceTypeQuery::Visibility);
			Trace.UseLine();
			Trace.IgnoreActor(Owner);
			Trace.IgnoreActor(Game::Mio);
			Trace.IgnoreActor(Game::Zoe);
			if (Game::Mio.AttachParentActor != nullptr)
				Trace.IgnoreActor(Game::Mio.AttachParentActor);
			if (Game::Zoe.AttachParentActor != nullptr)
				Trace.IgnoreActor(Game::Zoe.AttachParentActor);
			FHitResult Obstruction = Trace.QueryTraceSingle(CompanionComp.Player.ViewLocation, Owner.ActorLocation);
			bHasLOS = !Obstruction.bBlockingHit;
			CheckLOSTime = Time::GameTimeSeconds + LOSInterval;

			// HACK: Update obstructed stuff here for teleport check
			if (Obstruction.bBlockingHit)
			{
				CompanionComp.FollowObstructedTime = Time::GameTimeSeconds;
				CompanionComp.FollowObstruction = Obstruction;
			}
		}
		return !bHasLOS;		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		if (CompanionComp.State != EDarkPortalCompanionState::Obstructed)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;
		if (CompanionComp.State != EDarkPortalCompanionState::Obstructed)
			return true;
		if (UnobstructedDuration > Settings.UnobstructedDetectDuration)
			return true;
		if (Owner.ActorLocation.IsWithinDist(Destination, 60.0))
			return true; // We've arrived but might still be blocked. If this is an issue we need to handle seeking unobstructed follow location.
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CompanionComp.State = EDarkPortalCompanionState::Obstructed; // Makes sure remote side gets this		

		PlayerTrailComp = UTargetTrailComponent::Get(CompanionComp.Player);
		FVector StartLocation = Owner.ActorLocation;

		Destination = GetDestination();
		float Distance = Math::Max(Destination.Distance(StartLocation), 1.0);
		FVector StartTangent = Owner.ActorVelocity.GetClampedToMaxSize(Distance * 0.5);

		FVector ReachLevelLoc = Destination * 0.3 + StartLocation * 0.7;
		ReachLevelLoc.Z = Destination.Z;

		TArray<FVector> Points;
		Points.Add(StartLocation);
		Points.Add(ReachLevelLoc);
		Points.Add(Destination);
		Spline.SetPoints(Points);
		Spline.SetCustomEnterTangentPoint(StartLocation + StartTangent);

		Speed.SnapTo(Owner.ActorVelocity.Size());
		CurrentDistance = 0.0;

		bHasLOS = false;
		CheckLOSTime = Time::GameTimeSeconds + Settings.ObstructedReturnMinDuration;
		UnobstructedDuration = 0.0;

		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);
		AnimComp.RequestFeature(DarkPortalCompanionAnimTags::Follow, EBasicBehaviourPriority::Medium, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ResetObstructed();
		AnimComp.ClearFeature(this);
		bHasLOS = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(Movement))
			return;

		if(HasControl())
			ComposeMovement(DeltaTime);
		else
			Movement.ApplyCrumbSyncedAirMovement();

		MoveComp.ApplyMove(Movement);
	}

	void ComposeMovement(float DeltaTime)
	{
		if (DeltaTime == 0.0)
			return;

		Destination = GetDestination();
		Spline.SetPoint(Destination, Spline.Points.Num() - 1);

		float RemainingDistance = Spline.GetLength() - CurrentDistance;
		if (RemainingDistance > Settings.ObstructedNearRange)
			Speed.AccelerateTo(Settings.FollowFarSpeed, 1.0, DeltaTime);
		else if (RemainingDistance > Settings.ObstructedReturnNearMaxSpeed)
			Speed.AccelerateTo(Settings.ObstructedReturnNearMaxSpeed, 1.0, DeltaTime);
		else
			Speed.AccelerateTo(RemainingDistance, 1.0, DeltaTime);

		CurrentDistance += Speed.Value * DeltaTime;
		FVector NewLoc = Spline.GetLocationAtDistance(CurrentDistance);
		FVector Delta = NewLoc - Owner.ActorLocation;
		Movement.AddDeltaFromMoveToPositionWithCustomVelocity(NewLoc, Delta / DeltaTime);

		// Rotate to match player forward when close, velocity otherwise
		FVector Direction = Spline.GetDirectionAtDistance(CurrentDistance);
		FRotator Rotation;
		if (Owner.ActorLocation.IsWithinDist(Destination, 50.0))
			Rotation = MoveComp.GetStoppedRotation(3.0, DeltaTime);
		else
			Rotation = MoveComp.GetRotationTowardsDirection(Direction, 1.0, DeltaTime);
		Movement.SetRotation(Rotation);

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			TArray<FVector> Locs;
			Spline.GetLocations(Locs, 100);
			for (int i = 1; i < Locs.Num(); i++)
			{
				Debug::DrawDebugLine(Locs[i - 1], Locs[i], FLinearColor::Red, 3.0);
			}
		}
#endif		
	}

	FVector GetDestination()
	{
		AHazePlayerCharacter Player = CompanionComp.Player;		
		FRotator ViewRot = Player.ViewRotation;
		FVector FollowOffset = Settings.FollowOffsetMax;
		if (Math::Abs(Settings.FollowOffsetMax.Y) < Math::Abs(Settings.FollowOffsetMin.Y))
			FollowOffset.Y = Settings.FollowOffsetMin.Y;
		FVector Dest = Player.ActorLocation;
		Dest += Player.ActorForwardVector * FollowOffset.X;
		Dest += ViewRot.RightVector * FollowOffset.Y;
		Dest.Z = Player.ActorLocation.Z + FollowOffset.Z;

		// Add some prediction, more if player is moving away from camera
		FVector PlayerVelocity = PlayerTrailComp.GetAverageVelocity(0.5);
		PlayerVelocity.Z *= 0.2; // Reduce predicted vertical velocity
		float DirFactor = PlayerVelocity.GetSafeNormal().DotProduct(ViewRot.ForwardVector); 
		float PredictionTime = Math::GetMappedRangeValueClamped(FVector2D(-0.7, 1.0), FVector2D(0.0, 1.5), DirFactor);
		Dest += PlayerVelocity * PredictionTime;
		return Dest;
	}
};