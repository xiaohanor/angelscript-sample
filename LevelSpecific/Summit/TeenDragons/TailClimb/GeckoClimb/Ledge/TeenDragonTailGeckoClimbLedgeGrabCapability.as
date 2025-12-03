class UTeenDragonTailGeckoClimbLedgeGrabCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonTailClimb);
	
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 10;

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	UPlayerTailTeenDragonComponent TailDragonComp;
	UTeenDragonTailGeckoClimbComponent GeckoClimbComp;
	
	UHazeMovementComponent MoveComp;
	UTeleportingMovementData TeleportingMovement;
	USteppingMovementData SteppingMovement;
	
	UTeenDragonTailGeckoClimbSettings ClimbSettings;
	FVector Destination;
	float Speed;
	bool bMoveDone = false;
	FRotator StartRotation;

	float DistToDestination;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TailDragonComp = UPlayerTailTeenDragonComponent::Get(Player);
		GeckoClimbComp = UTeenDragonTailGeckoClimbComponent::Get(Player);

		MoveComp = UHazeMovementComponent::Get(Player);
		TeleportingMovement = MoveComp.SetupTeleportingMovementData();
		SteppingMovement = MoveComp.SetupSteppingMovementData();
		
		ClimbSettings = UTeenDragonTailGeckoClimbSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTeenDragonTailGeckoClimbLedgeGrabActivatedParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!TailDragonComp.IsClimbing() || GeckoClimbComp.bIsGeckoJumping)
			return false;

		FVector TempDestination;
		if(!TraceForLedgeGrab(TempDestination))
			return false;

		Params.Destination = TempDestination;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(bMoveDone)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTeenDragonTailGeckoClimbLedgeGrabActivatedParams Params)
	{
		Destination = Params.Destination;
		DistToDestination = Destination.Distance(Player.ActorLocation);

		Speed = Destination.Distance(Player.ActorLocation) / TeenDragonTailGeckoClimbLedgeGrabSettings::LedgeGrabDuration;
		bMoveDone = false;

		GeckoClimbComp.OverrideCameraTransitionAlpha(0.0);
		Player.ApplyBlendToCurrentView(TeenDragonTailGeckoClimbLedgeGrabSettings::LedgeGrabDuration * 2.0);
		StartRotation = Player.ActorRotation;
		GeckoClimbComp.bIsLedgeGrabbing = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		GeckoClimbComp.bIsLedgeGrabbing = false;
		GeckoClimbComp.StopClimbing();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = 0.0;
		if(ActiveDuration > TeenDragonTailGeckoClimbLedgeGrabSettings::AnticipationDelay)
			Alpha = (ActiveDuration - TeenDragonTailGeckoClimbLedgeGrabSettings::AnticipationDelay) / TeenDragonTailGeckoClimbLedgeGrabSettings::RotationDuration;

		if(Alpha >= 1.0)
			Alpha = 1.0;

		FVector Direction = (Destination - Player.ActorLocation).GetSafeNormal();
		FVector HorizontalDirection = FVector(Direction.X, Direction.Y, 0.0); // We don't want this normalized since we only want the horizontal part to be treated as velocity
		FRotator CurrentRotation = FQuat::Slerp(StartRotation.Quaternion(), FRotator::MakeFromXZ(HorizontalDirection.GetSafeNormal(), FVector::UpVector).Quaternion(), Alpha).Rotator();

		float MoveDelta = Speed * DeltaTime;

		TEMPORAL_LOG(Player, "Climb Ledge Up")
			.Sphere("Destination", Destination, 20, FLinearColor::Purple)
			.Value("Move Delta", MoveDelta)
			.Value("Dist to Destination", DistToDestination)
		;

		if(MoveComp.PrepareMove(TeleportingMovement, CurrentRotation.UpVector))
		{
			if(HasControl())
			{
				if(ActiveDuration > TeenDragonTailGeckoClimbLedgeGrabSettings::AnticipationDelay)
				{
					float ActualMoveDelta = MoveDelta;
					if(MoveDelta > DistToDestination)
					{
						FHazeTraceSettings GroundTrace;
						GroundTrace = Trace::InitFromPrimitiveComponent(Player.CapsuleComponent);
						GroundTrace.IgnorePlayers();
						FVector TraceOrigin = Destination + FVector::UpVector * (Player.CapsuleComponent.ScaledCapsuleRadius + 10.0);
						FVector TraceDestination = TraceOrigin - FVector::UpVector * 20;
						FHitResult Hit = GroundTrace.QueryTraceSingle(TraceOrigin, TraceDestination);
						TeleportingMovement.OverrideFinalGroundResult(Hit);
						bMoveDone = true;

						if(TeenDragonTailGeckoClimbLedgeGrabSettings::bBlockLandingEffectsAfterLedgeGrab)
							TailDragonComp.bLandingBlockedThisFrame = true;

						ActualMoveDelta = DistToDestination;
					}
					TeleportingMovement.AddDeltaWithCustomVelocity(Direction * ActualMoveDelta, (HorizontalDirection * ActualMoveDelta) / DeltaTime);
				}
			}
			else
			{
				TeleportingMovement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMove(TeleportingMovement);
			TailDragonComp.RequestLocomotionDragonAndPlayer(TeenDragonLocomotionTags::TailTeenClimb);
		}
		DistToDestination -= MoveDelta;
	}

	bool TraceForLedgeGrab(FVector&out Out_Destination) const
	{
		// Trace loop:
		// 1. Find destination on top of the wall (Purple)
		// 2. Trace upward to check for any vertical blockers (Blue)
		// 3. Trace horizontally from highest point to destination to check for any horizontal blockers (Green)

		FVector WallUp = GeckoClimbComp.CurrentClimbParams.ClimbComp.Owner.ActorUpVector;

		float SphereRadius = Player.CapsuleComponent.ScaledCapsuleRadius;
		FHazeTraceSettings SphereTrace;
		SphereTrace.TraceWithProfile(n"PlayerCharacter");
		SphereTrace.UseSphereShape(SphereRadius);

		if(IsDebugActive())
		{
			Console::ExecuteConsoleCommand("FlushPersistentDebugLines");
			FHazeTraceDebugSettings DebugSettings = TraceDebug::MakeDuration(3.0);
			DebugSettings.Thickness = 5;
			DebugSettings.TraceColor = FLinearColor::Purple;
			SphereTrace.DebugDraw(DebugSettings);

			const float DebugLedgeWidth = 200.0;
			const float DebugLedgeDepth = 100.0;
			FVector BottomLeft = Player.ActorLocation - Player.ActorRightVector * DebugLedgeWidth;
			FVector TopLeft = BottomLeft + Player.ActorForwardVector * TeenDragonTailGeckoClimbLedgeGrabSettings::LedgeGrabMaxDistance;
			FVector BackLeft = TopLeft - Player.ActorUpVector * DebugLedgeDepth;
			FVector BottomRight = Player.ActorLocation + Player.ActorRightVector * DebugLedgeWidth;
			FVector TopRight = BottomRight + Player.ActorForwardVector * TeenDragonTailGeckoClimbLedgeGrabSettings::LedgeGrabMaxDistance;
			FVector BackRight = TopRight - Player.ActorUpVector * DebugLedgeDepth;

			Debug::DrawDebugLine(BottomLeft, TopLeft, FLinearColor::Red, 5, 3.0);
			Debug::DrawDebugLine(BottomRight, TopRight, FLinearColor::Red, 5, 3.0);
			Debug::DrawDebugLine(TopLeft, TopRight, FLinearColor::Red, 5, 3.0);
			Debug::DrawDebugLine(TopRight, BackRight, FLinearColor::Red, 5, 3.0);
			Debug::DrawDebugLine(TopLeft, BackLeft, FLinearColor::Red, 5, 3.0);
		}

		

		FVector WallNormal = Player.ActorUpVector;
		FVector Origin = Player.ActorLocation;
		
		FVector DownTraceEnd = Origin - WallNormal * TeenDragonTailGeckoClimbLedgeGrabSettings::LedgeGrabFinalPositionClearance;
		FVector DownTraceOrigin = DownTraceEnd + WallUp * (TeenDragonTailGeckoClimbLedgeGrabSettings::LedgeGrabMaxDistance + SphereRadius);
		FHitResult DestinationHit = SphereTrace.QueryTraceSingle(DownTraceOrigin, DownTraceEnd);

		// To stop trying to ledge up other directions than upwards
		if(!DestinationHit.ImpactNormal.Equals(FVector::UpVector, 0.4))
			return false;

		if(DestinationHit.bStartPenetrating)
			return false;

		Out_Destination = DestinationHit.Location - DestinationHit.ImpactNormal * SphereRadius;

		if(IsDebugActive())
		{
			FHazeTraceDebugSettings DebugSettings = TraceDebug::MakeDuration(3.0);
			DebugSettings.Thickness = 5;
			DebugSettings.TraceColor = FLinearColor::LucBlue;
			SphereTrace.DebugDraw(DebugSettings);
		}

		FVector UpTraceOrigin = Origin + WallNormal * (SphereRadius + 1.0);
		FVector UpTraceEnd = UpTraceOrigin + WallUp * ((DestinationHit.Location - UpTraceOrigin).DotProduct(WallUp) + KINDA_SMALL_NUMBER);
		FHitResult UpHit = SphereTrace.QueryTraceSingle(UpTraceOrigin, UpTraceEnd);

		if(UpHit.bStartPenetrating || UpHit.bBlockingHit)
			return false;

		if(IsDebugActive())
		{
			FHazeTraceDebugSettings DebugSettings = TraceDebug::MakeDuration(3.0);
			DebugSettings.Thickness = 5;
			DebugSettings.TraceColor = FLinearColor::Green;
			SphereTrace.DebugDraw(DebugSettings);
		}

		FVector ForwardTraceOrigin = UpTraceEnd;
		FVector ForwardTraceEnd = DestinationHit.Location + DestinationHit.Normal;

		FHitResult ForwardHit = SphereTrace.QueryTraceSingle(ForwardTraceOrigin, ForwardTraceEnd);

		if(ForwardHit.bStartPenetrating || ForwardHit.bBlockingHit)
			return false;

		return true;
	}
}

struct FTeenDragonTailGeckoClimbLedgeGrabActivatedParams
{
	FVector Destination;
}