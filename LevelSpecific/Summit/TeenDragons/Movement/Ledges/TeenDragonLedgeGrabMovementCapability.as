class UTeenDragonLedgeGrabMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonLedgeGrab);
	default CapabilityTags.Add(CapabilityTags::Movement);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 10;

	UPlayerMovementComponent MoveComp;
	UTeleportingMovementData Movement;
	UPlayerTeenDragonComponent DragonComp;

	USceneComponent LedgeGrabComponent;
	float Speed;
	bool bMoveDone = false;

	// Relative to ledge grab component
	FVector RelativeTargetLocation;
	FVector RelativeStartLocation;

	FQuat StartRelativeRotation;
	FQuat TargetRelativeRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		DragonComp = UPlayerTeenDragonComponent::Get(Player);
		Movement = MoveComp.SetupTeleportingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTeenDragonLedgeGrabMovementActivatedParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(MoveComp.HasGroundContact())
			return false;

		auto TraceParams = TraceForLedgeGrab();
		if(!TraceParams.IsSet())
			return false;

		Params = TraceParams.Value;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(bMoveDone)
			return true;
		
		const float TotalDuration = TeenDragonLedgeGrabSettings::AnticipationDelay  
			+ TeenDragonLedgeGrabSettings::LedgeGrabDuration;

		if(ActiveDuration > TotalDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTeenDragonLedgeGrabMovementActivatedParams Params)
	{
		MoveComp.StopFalling(Player.ActorLocation, MoveComp.Velocity);
		RelativeTargetLocation = Params.RelativeTargetLocation;

		LedgeGrabComponent = Params.ClimbComponent;
		RelativeStartLocation = Player.ActorLocation - LedgeGrabComponent.WorldLocation;
		MoveComp.FollowComponentMovement(LedgeGrabComponent, this, EMovementFollowComponentType::Teleport);

		Speed = RelativeTargetLocation.Distance(RelativeStartLocation) / TeenDragonLedgeGrabSettings::LedgeGrabDuration;
		StartRelativeRotation = Player.ActorQuat * LedgeGrabComponent.ComponentQuat.Inverse();

		TargetRelativeRotation = Params.RelativeTargetRotation;
	
		bMoveDone = false;
		Player.BlockCapabilities(TeenDragonCapabilityTags::TeenDragonLedgeDown, this);
		Player.BlockCapabilities(TeenDragonCapabilityTags::TeenDragonLedgeFall, this);

		DragonComp.bIsLedgeGrabbing = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(TeenDragonLedgeGrabSettings::bBlockLandingEffectsAfterLedgeGrab)
			DragonComp.bLandingBlockedThisFrame = true;

		MoveComp.UnFollowComponentMovement(this);
		Player.UnblockCapabilities(TeenDragonCapabilityTags::TeenDragonLedgeDown, this);
		Player.UnblockCapabilities(TeenDragonCapabilityTags::TeenDragonLedgeFall, this);
		bMoveDone = true;

		DragonComp.bIsLedgeGrabbing = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				if(ActiveDuration > TeenDragonLedgeGrabSettings::AnticipationDelay)
				{
					float LedgeUpAlpha = (ActiveDuration + TeenDragonLedgeGrabSettings::AnticipationDelay) 
						/ (TeenDragonLedgeGrabSettings::AnticipationDelay + TeenDragonLedgeGrabSettings::LedgeGrabDuration);

					LedgeUpAlpha = Math::Clamp(LedgeUpAlpha, 0.0, 1.0);

					FVector TargetRelativeLocation = Math::Lerp(RelativeStartLocation, RelativeTargetLocation, LedgeUpAlpha);
					FVector TargetLocation = LedgeGrabComponent.WorldLocation + TargetRelativeLocation;
					FVector Delta = TargetLocation - Player.ActorLocation;
					FVector Velocity = Delta / DeltaTime;
					Velocity = Velocity.ConstrainToPlane(FVector::UpVector);

					if(!TeenDragonLedgeGrabSettings::bInheritVelocityAfterLedgeGrab)
						Velocity = FVector::ZeroVector;
					
					Movement.AddDeltaWithCustomVelocity(Delta, Velocity);

					FHazeTraceSettings GroundTrace;
					FHazeTraceShape TraceShape = FHazeTraceShape::MakeFromComponent(Player.CapsuleComponent);
					GroundTrace.UseShape(TraceShape);
					GroundTrace.TraceWithPlayerProfile(Player);
					GroundTrace.IgnorePlayers();
					FVector Start = LedgeGrabComponent.WorldLocation + RelativeTargetLocation
						+ FVector::UpVector * (Player.CapsuleComponent.ScaledCapsuleRadius + 100.0);

					FVector End = Start + FVector::DownVector * 200;
					FHitResult Hit = GroundTrace.QueryTraceSingle(Start, End);
					TEMPORAL_LOG(Player, "Teen Dragon Ledge Grab").HitResults("Ground Override Trace", Hit, TraceShape);
					Movement.OverrideFinalGroundResult(Hit, false);

					float LedgeUpTurnAlpha = (ActiveDuration + TeenDragonLedgeGrabSettings::AnticipationDelay) 
						/ (TeenDragonLedgeGrabSettings::AnticipationDelay + TeenDragonLedgeGrabSettings::LedgeGrabTurnDuration);

					LedgeUpTurnAlpha = Math::Clamp(LedgeUpTurnAlpha, 0.0, 1.0);

					FQuat RelativeRotation = FQuat::Slerp(StartRelativeRotation, TargetRelativeRotation, LedgeUpTurnAlpha);
					FQuat Rotation = RelativeRotation * LedgeGrabComponent.ComponentQuat; 
					Movement.SetRotation(Rotation);

					TEMPORAL_LOG(Player, "Teen Dragon Ledge Grab")
						.Sphere("Start Location", LedgeGrabComponent.WorldLocation + RelativeStartLocation, 50, FLinearColor::Red)
						.Sphere("Target Location", TargetLocation, 50, FLinearColor::White)
						.Sphere("Destination", LedgeGrabComponent.WorldLocation + RelativeTargetLocation, 50, FLinearColor::Green)
						.Value("Turn Alpha", LedgeUpTurnAlpha)
						.Value("Alpha", LedgeUpAlpha)
						.Rotation("Start Rotation", LedgeGrabComponent.ComponentQuat * StartRelativeRotation, Player.ActorLocation, 500.0)
						.Rotation("Target Rotation", LedgeGrabComponent.ComponentQuat * TargetRelativeRotation, Player.ActorLocation, 500.0)
					;
				}
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMove(Movement);
			DragonComp.RequestLocomotionDragonAndPlayer(TeenDragonLocomotionTags::TeenDragonLedgeUp);
		}
	}

	TOptional<FTeenDragonLedgeGrabMovementActivatedParams> TraceForLedgeGrab() const
	{
		TOptional<FTeenDragonLedgeGrabMovementActivatedParams> Params;
		auto TemporalLog = TEMPORAL_LOG(Player, "Teen Dragon Ledge Grab");

		// Trace loop:
		// 1. Check if there is a wall in front of the dragon within wall max distance of the collider (Purple)
		// 2. Find destination on top of the wall (Orange)
		// 3. Trace upward to check for any vertical blockers (Blue)
		// 4. Trace horizontally from highest point to destination to check for any horizontal blockers (Green)

		float SphereRadius = Player.CapsuleComponent.ScaledCapsuleRadius;
		FHazeTraceSettings SphereTrace;
		FHazeTraceShape SphereShape = FHazeTraceShape::MakeFromComponent(Player.CapsuleComponent);
		SphereTrace.TraceWithProfile(n"PlayerCharacter");
		SphereTrace.UseShape(SphereShape);


		if(IsDebugActive())
		{
			Console::ExecuteConsoleCommand("FlushPersistentDebugLines");
			FHazeTraceDebugSettings DebugSettings = TraceDebug::MakeDuration(3.0);
			DebugSettings.Thickness = 5;
			DebugSettings.TraceColor = FLinearColor::Purple;
			SphereTrace.DebugDraw(DebugSettings);

			const float DebugLedgeWidth = 200.0;
			const float DebugLedgeDepth = 100.0;
			FVector BottomLeft = Player.ActorLocation + Player.ActorForwardVector * (SphereRadius + TeenDragonLedgeGrabSettings::WallMaxDistance) - Player.ActorRightVector * DebugLedgeWidth;
			FVector TopLeft = BottomLeft + Player.ActorUpVector * (TeenDragonLedgeGrabSettings::LedgeGrabMaxHeight + SphereRadius);
			FVector BackLeft = TopLeft + Player.ActorForwardVector * DebugLedgeDepth;
			FVector BottomRight = Player.ActorLocation + Player.ActorForwardVector * (SphereRadius + TeenDragonLedgeGrabSettings::WallMaxDistance) + Player.ActorRightVector * DebugLedgeWidth;
			FVector TopRight = BottomRight + Player.ActorUpVector * (TeenDragonLedgeGrabSettings::LedgeGrabMaxHeight + SphereRadius);
			FVector BackRight = TopRight + Player.ActorForwardVector * DebugLedgeDepth;

			Debug::DrawDebugLine(BottomLeft, TopLeft, FLinearColor::Red, 5, 3.0);
			Debug::DrawDebugLine(BottomRight, TopRight, FLinearColor::Red, 5, 3.0);
			Debug::DrawDebugLine(TopLeft, TopRight, FLinearColor::Red, 5, 3.0);
			Debug::DrawDebugLine(TopRight, BackRight, FLinearColor::Red, 5, 3.0);
			Debug::DrawDebugLine(TopLeft, BackLeft, FLinearColor::Red, 5, 3.0);
		}

		FVector WallTraceOrigin = Player.CapsuleComponent.WorldLocation + MoveComp.WorldUp * SphereRadius;
		FVector WallTraceEnd = WallTraceOrigin + Player.ActorForwardVector * TeenDragonLedgeGrabSettings::WallMaxDistance;
		FHitResult WallHit = SphereTrace.QueryTraceSingle(WallTraceOrigin, WallTraceEnd);

		TemporalLog.HitResults("Wall Trace", WallHit, SphereShape);
		if(!(WallHit.bBlockingHit && WallHit.Component.HasTag(n"LedgeClimbable")))
			return Params;

		FVector WallNormal = WallHit.ImpactNormal;
		FVector ImpactPoint = WallHit.ImpactPoint;

		// A rotator that is only yawed in the direction of the wall and nothing more
		FRotator TopRotationComparand = FRotator::MakeFromZX(MoveComp.WorldUp, WallNormal);
		FRotator WallSideRotation = FRotator::MakeFromXZ(WallNormal, MoveComp.WorldUp);

		const FVector WallPitchVector = WallSideRotation.UpVector.ConstrainToPlane(TopRotationComparand.RightVector).GetSafeNormal();
		const float WallPitchAngle = Math::RadiansToDegrees(WallPitchVector.AngularDistance(TopRotationComparand.UpVector) * Math::Sign(WallPitchVector.DotProduct(TopRotationComparand.ForwardVector))); 

		TemporalLog
			.DirectionalArrow("Wall Pitch Vector", Player.ActorLocation + Player.ActorUpVector * 500, WallPitchVector, 10, 4000, FLinearColor::MakeFromHex(0xfffe9800))
			.Value("Wall Pitch Angle", WallPitchAngle)
		;

		if (WallPitchAngle < TeenDragonLedgeGrabSettings::WallPitchMinimum - KINDA_SMALL_NUMBER
			|| WallPitchAngle > TeenDragonLedgeGrabSettings::WallPitchMaximum + KINDA_SMALL_NUMBER)
			return Params;

		if(IsDebugActive())
		{
			Debug::DrawDebugCoordinateSystem(ImpactPoint + WallNormal * 1.0, WallSideRotation, 150, 5, 3.0);
			FHazeTraceDebugSettings DebugSettings = TraceDebug::MakeDuration(3.0);
			DebugSettings.Thickness = 5;
			DebugSettings.TraceColor = FLinearColor::MakeFromHex(0xfffe9800);
			SphereTrace.DebugDraw(DebugSettings);
		}
		
		FVector DownTraceEnd = ImpactPoint - WallNormal * (SphereRadius + TeenDragonLedgeGrabSettings::LedgeGrabFinalPositionClearance);
		FVector DownTraceOrigin = DownTraceEnd + WallSideRotation.UpVector * TeenDragonLedgeGrabSettings::LedgeGrabMaxHeight;
		FHitResult DestinationHit = SphereTrace.QueryTraceSingle(DownTraceOrigin, DownTraceEnd);

		TemporalLog.HitResults("Destination Hit", DestinationHit, SphereShape);

		if(DestinationHit.bStartPenetrating)
			return Params;

		FVector DirToDestination = (DestinationHit.ImpactPoint - Player.ActorLocation).ConstrainToPlane(Player.ActorUpVector).GetSafeNormal();
		float SpeedTowardsDestinationHit = MoveComp.Velocity.DotProduct(DirToDestination);
		TemporalLog
			.DirectionalArrow("Direction Towards Destination", Player.ActorLocation, DirToDestination * 1000.0, 10, 4000, FLinearColor::DPink)
			.Value("Speed Towards Destination Hit", SpeedTowardsDestinationHit)
		;
		if(SpeedTowardsDestinationHit < 1.0)
			return Params;

		if(IsDebugActive())
		{
			FHazeTraceDebugSettings DebugSettings = TraceDebug::MakeDuration(3.0);
			DebugSettings.Thickness = 5;
			DebugSettings.TraceColor = FLinearColor::LucBlue;
			SphereTrace.DebugDraw(DebugSettings);
		}

		FVector UpTraceOrigin = ImpactPoint + WallNormal * (SphereRadius + 1.0);
		FVector UpTraceEnd = UpTraceOrigin + WallSideRotation.UpVector * ((DestinationHit.Location - UpTraceOrigin).DotProduct(WallSideRotation.UpVector) + KINDA_SMALL_NUMBER);
		FHitResult UpHit = SphereTrace.QueryTraceSingle(UpTraceOrigin, UpTraceEnd);

		TemporalLog.HitResults("Up Hit", UpHit, SphereShape);
		if(UpHit.bStartPenetrating || UpHit.bBlockingHit)
			return Params;

		if(IsDebugActive())
		{
			FHazeTraceDebugSettings DebugSettings = TraceDebug::MakeDuration(3.0);
			DebugSettings.Thickness = 5;
			DebugSettings.TraceColor = FLinearColor::Green;
			SphereTrace.DebugDraw(DebugSettings);
		}

		FVector ForwardTraceOrigin = UpTraceEnd;
		FVector ForwardTraceEnd = DestinationHit.Location + DestinationHit.Normal * KINDA_SMALL_NUMBER;

		FHitResult ForwardHit = SphereTrace.QueryTraceSingle(ForwardTraceOrigin, ForwardTraceEnd);

		TemporalLog.HitResults("Forward Hit", ForwardHit, SphereShape);
		if(ForwardHit.bStartPenetrating || ForwardHit.bBlockingHit)
			return Params;
		
		FTeenDragonLedgeGrabMovementActivatedParams TraceParams;
		TraceParams.ClimbComponent = WallHit.Component;

		FVector TargetLocation = DestinationHit.Location - DestinationHit.ImpactNormal * SphereRadius;
		TraceParams.RelativeTargetLocation = TargetLocation - WallHit.Component.WorldLocation;

		FVector DirToDest = TargetLocation - Player.ActorLocation;
		DirToDest = DirToDest.ConstrainToPlane(Player.ActorUpVector).GetSafeNormal();
		FQuat TargetRotation = FQuat::MakeFromXZ(DirToDest, Player.ActorUpVector);
		TraceParams.RelativeTargetRotation = TargetRotation * WallHit.Component.ComponentQuat.Inverse();

		Params.Set(TraceParams);
		return Params;
	}
}

struct FTeenDragonLedgeGrabMovementActivatedParams
{
	FVector RelativeTargetLocation;
	FQuat RelativeTargetRotation;
	USceneComponent ClimbComponent;
}