struct FTeenDragonLedgeFallParams
{
	FVector TargetLocation;
	float Duration;
}

class UTeenDragonLedgeFallCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonLedgeFall);
	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 92;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	UTeleportingMovementData Movement;
	UPlayerTeenDragonComponent DragonComp;

	UTeenDragonLedgeDownSettings Settings;

	FTeenDragonLedgeFallParams CurrentParams;
	FVector StartLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerTeenDragonComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupTeleportingMovementData();

		Settings = UTeenDragonLedgeDownSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTeenDragonLedgeFallParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!MoveComp.IsOnWalkableGround())
			return false;

		auto LedgeParams = TraceForLedgeFall();
		if(!LedgeParams.IsSet()) 
			return false;

		Params = LedgeParams.Value;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(ActiveDuration > CurrentParams.Duration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTeenDragonLedgeFallParams Params)
	{	
		CurrentParams = Params;
		StartLocation = Player.ActorLocation + MoveComp.Velocity * Time::GetActorDeltaSeconds(Player);

		Player.BlockCapabilities(TeenDragonCapabilityTags::TeenDragonLedgeGrab, this);
		Player.BlockCapabilities(TeenDragonCapabilityTags::TeenDragonLedgeDown, this);

		DragonComp.bIsLedgeFalling = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(TeenDragonCapabilityTags::TeenDragonLedgeGrab, this);
		Player.UnblockCapabilities(TeenDragonCapabilityTags::TeenDragonLedgeDown, this);

		DragonComp.bIsLedgeFalling = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				float LedgeFallAlpha = ActiveDuration / CurrentParams.Duration;
				LedgeFallAlpha = Math::Saturate(LedgeFallAlpha);

				FVector FrameLocation = Math::Lerp(StartLocation, CurrentParams.TargetLocation, LedgeFallAlpha);

				FVector DeltaToLocation = FrameLocation - Player.ActorLocation;
				FVector HorizontalDeltaToLocation = DeltaToLocation.ConstrainToPlane(MoveComp.WorldUp);
				Movement.AddDelta(HorizontalDeltaToLocation);
				Movement.AddGravityAcceleration();
				Movement.AddOwnerVerticalVelocity();
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMove(Movement);
			DragonComp.RequestLocomotionDragonAndPlayer(TeenDragonLocomotionTags::AirMovement);
		}
	}

	TOptional<FTeenDragonLedgeFallParams> TraceForLedgeFall() const
	{
		TOptional<FTeenDragonLedgeFallParams> Params;
		
		auto TemporalLog = TEMPORAL_LOG(Player, "Teen Dragon Ledge Fall");

		FHazeTraceSettings DownTrace;
		DownTrace.UseLine();
		DownTrace.TraceWithPlayerProfile(Player);
		FVector DownTraceEnd = Player.ActorLocation
			+ Player.ActorForwardVector * 300.0
			- Player.ActorUpVector * 100;
		
		FVector DownTraceStart = DownTraceEnd + Player.ActorUpVector * 200.0;
		auto DownTraceHit = DownTrace.QueryTraceSingle(DownTraceStart, DownTraceEnd);
		TemporalLog.HitResults("Down Trace Hit", DownTraceHit, FHazeTraceShape::MakeLine());
		if(DownTraceHit.bBlockingHit)
			return Params;

		FHazeTraceSettings WallTrace;
		WallTrace.UseLine();
		WallTrace.TraceWithPlayerProfile(Player);
		FVector WallTraceStart = DownTraceEnd;
		FVector WallTraceEnd = WallTraceStart
			- Player.ActorForwardVector * 400.0;

		auto WallTraceHit = WallTrace.QueryTraceSingle(WallTraceStart, WallTraceEnd);

		float AngleToUp = Math::RadiansToDegrees(WallTraceHit.Normal.AngularDistanceForNormals(Player.ActorUpVector));
		TemporalLog
			.HitResults("Wall Trace Hit", WallTraceHit, FHazeTraceShape::MakeLine())
			.Value("Wall Normal Angle to Up", AngleToUp)
		;
		if(AngleToUp < 60.0)
			return Params;	

		// IDK what would cause this
		if(!WallTraceHit.bBlockingHit)
			return Params;

		// Probably not at an edge
		if(WallTraceHit.bStartPenetrating)
			return Params;
		
		const float SpeedTowardsLedge = MoveComp.Velocity.DotProduct(WallTraceHit.Normal);
		const float SpeedAlpha = Math::GetPercentageBetween(Settings.FallSpeedTowardLedgeForForwardOffset.Min, Settings.FallSpeedTowardLedgeForForwardOffset.Max, SpeedTowardsLedge);
		const float ForwardOffset = Settings.FallGroundTraceForwardOffset.Lerp(SpeedAlpha);
		TemporalLog
			.Value("Speed Towards Ledge", SpeedTowardsLedge)
			.Value("Speed Alpha", SpeedAlpha)
			.Value("Forward Offset", ForwardOffset)
		;

		FHazeTraceShape PlayerShape = FHazeTraceShape::MakeFromComponent(Player.CapsuleComponent);
		FHazeTraceSettings GroundVerificationTrace;
		GroundVerificationTrace.UseLine();
		GroundVerificationTrace.TraceWithPlayerProfile(Player);

		const FVector TraceUpDir = Player.ActorUpVector; 

		FVector Start = Player.ActorLocation
			+ Player.ActorForwardVector * ForwardOffset;
		FVector End = Start 
			- TraceUpDir * Settings.FallTargetLocationDownOffset; 
		auto GroundVerificationHit = GroundVerificationTrace.QueryTraceSingle(Start, End);
		auto GroundVerificationPage = TemporalLog.Page("Ground Verification");
		GroundVerificationPage.HitResults("Hit", GroundVerificationHit, FHazeTraceShape::MakeLine());

		// Found ground, should do ledge down instead
		if(GroundVerificationHit.bBlockingHit)
			return Params;

		// Not valid hit
		if(GroundVerificationHit.bStartPenetrating)
			return Params;

		FHazeTraceSettings GroundWidthTrace;
		GroundWidthTrace.UseShape(PlayerShape);
		GroundWidthTrace.TraceWithPlayerProfile(Player);

		FVector TargetLocation = Player.ActorLocation 
			+ Player.ActorForwardVector * ForwardOffset
			- Player.ActorUpVector * Settings.FallTargetLocationDownOffset;
		End = TargetLocation;

		auto GroundWidthTraceHits = GroundWidthTrace.QueryTraceMulti(Start, End);
		auto GroundWidthPage = TemporalLog.Page("Ground Width");
		GroundWidthPage.HitResults("Ground Width Trace Hits", GroundWidthTraceHits, Start, End, PlayerShape);
		for(auto Hit : GroundWidthTraceHits)
		{
			// Found Impact, cant fall through it
			if(!Hit.bBlockingHit)
				continue;
		
			if(Hit.bStartPenetrating)
				return Params;

			const FVector DeltaToWidthHit = Hit.ImpactPoint - Start; 
			const float WidthHitDownDistance = DeltaToWidthHit.DotProduct(-Player.ActorUpVector);

			GroundWidthPage
				.DirectionalArrow(f"Hit {Hit.Actor.Name} : Delta to Hit", Start, DeltaToWidthHit, 10, 4000, FLinearColor::Black)
				.Value(f"Hit {Hit.Actor.Name} : Hit Down Distance", WidthHitDownDistance)
			;
		}

		FTeenDragonLedgeFallParams LedgeFallParams;
		LedgeFallParams.TargetLocation = TargetLocation;

		float HorizontalDistToTarget = (Player.ActorLocation.Dist2D(TargetLocation, MoveComp.WorldUp));
		if(Math::IsNearlyZero(HorizontalDistToTarget))
			return Params;

		float HorizontalSpeed = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp).Size();
		if(HorizontalSpeed >= KINDA_SMALL_NUMBER)
			LedgeFallParams.Duration = HorizontalDistToTarget / HorizontalSpeed;
		else
			LedgeFallParams.Duration = Settings.LedgeFallMaxDuration;
		LedgeFallParams.Duration = Math::Min(LedgeFallParams.Duration, Settings.LedgeFallMaxDuration);
		TemporalLog
			.Value("Horizontal Dist to Target", HorizontalDistToTarget)
			.Value("Horizontal Speed", HorizontalSpeed)
			.Value("Duration", LedgeFallParams.Duration)
		;

		Params.Set(LedgeFallParams);

		return Params;
	}
}