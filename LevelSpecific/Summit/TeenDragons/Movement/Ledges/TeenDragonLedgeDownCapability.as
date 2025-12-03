struct FTeenDragonLedgeDownParams
{
	USceneComponent LedgeDownComponent;
	FVector TargetRelativeLocation;
	FRotator TargetRelativeRotation;
}

class UTeenDragonLedgeDownCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonLedgeDown);
	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 91;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	UTeleportingMovementData Movement;
	UPlayerTeenDragonComponent DragonComp;

	UTeenDragonLedgeDownSettings Settings;

	FTeenDragonLedgeDownParams CurrentParams;
	FVector StartRelativeLocation;
	FRotator StartRelativeRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerTeenDragonComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupTeleportingMovementData();

		Settings = UTeenDragonLedgeDownSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTeenDragonLedgeDownParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!MoveComp.IsOnWalkableGround())
			return false;

		if (MoveComp.GroundContact.Component != nullptr)
		{
			if (!MoveComp.GroundContact.Component.HasTag(ComponentTags::LedgeClimbable))
				return false;
		}
		
		auto LedgeParams = TraceForLedgeDown();
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

		if(ActiveDuration > Settings.LedgeDownDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTeenDragonLedgeDownParams Params)
	{	
		CurrentParams = Params;
		StartRelativeLocation = Player.ActorLocation - Params.LedgeDownComponent.WorldLocation;
		StartRelativeLocation += MoveComp.Velocity * Time::GetActorDeltaSeconds(Player);
		StartRelativeRotation = Player.ActorRotation - Params.LedgeDownComponent.WorldRotation;

		Player.BlockCapabilities(TeenDragonCapabilityTags::TeenDragonLedgeGrab, this);
		Player.BlockCapabilities(TeenDragonCapabilityTags::TeenDragonLedgeFall, this);

		MoveComp.FollowComponentMovement(Params.LedgeDownComponent, this, EMovementFollowComponentType::Teleport);

		DragonComp.bIsLedgeDowning = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(TeenDragonCapabilityTags::TeenDragonLedgeGrab, this);
		Player.UnblockCapabilities(TeenDragonCapabilityTags::TeenDragonLedgeFall, this);

		MoveComp.UnFollowComponentMovement(this);

		DragonComp.bIsLedgeDowning = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				FHazeTraceSettings GroundTrace;
				FHazeTraceShape TraceShape = FHazeTraceShape::MakeFromComponent(Player.CapsuleComponent);
				GroundTrace.UseShape(TraceShape);
				GroundTrace.TraceWithPlayerProfile(Player);
				GroundTrace.IgnorePlayers();
				FVector TraceStart = CurrentParams.LedgeDownComponent.WorldLocation + CurrentParams.TargetRelativeLocation
					+ FVector::UpVector * (Player.CapsuleComponent.ScaledCapsuleRadius + 500.0);

				FVector TraceEnd = TraceStart + FVector::DownVector * 1000;
				FHitResult Hit = GroundTrace.QueryTraceSingle(TraceStart, TraceEnd);
				auto TemporalLog = TEMPORAL_LOG(Player, "Teen Dragon Ledge Down");
				TemporalLog.HitResults("Ground Override Trace", Hit, TraceShape);

				FVector EndRelativeLocation = CurrentParams.TargetRelativeLocation;
				if(Hit.bBlockingHit)
				{
					EndRelativeLocation = Hit.ImpactPoint - CurrentParams.LedgeDownComponent.WorldLocation;
					Movement.OverrideFinalGroundResult(Hit, false);
				}
				TemporalLog.Sphere("End Location", EndRelativeLocation + CurrentParams.LedgeDownComponent.WorldLocation, 50, FLinearColor::LucBlue, 5);
				
				float LedgeDownAlpha = ActiveDuration / Settings.LedgeDownDuration;
				LedgeDownAlpha = Math::Saturate(LedgeDownAlpha);
				LedgeDownAlpha = Math::EaseInOut(0.0, 1.0, LedgeDownAlpha, 2);

				FVector FrameLocation = Math::Lerp(StartRelativeLocation, EndRelativeLocation, LedgeDownAlpha) + CurrentParams.LedgeDownComponent.WorldLocation;

				float LedgeDownRotateAlpha = ActiveDuration / Settings.LedgeDownTurnDuration;
				LedgeDownRotateAlpha = Math::Saturate(LedgeDownRotateAlpha);

				FRotator FrameRotation = Math::LerpShortestPath(StartRelativeRotation, CurrentParams.TargetRelativeRotation, LedgeDownRotateAlpha) + CurrentParams.LedgeDownComponent.WorldRotation;

				Movement.SetRotation(FrameRotation);

				FVector DeltaToLocation = FrameLocation - Player.ActorLocation;
				FVector FlatVelocity = (DeltaToLocation / DeltaTime).ConstrainToPlane(MoveComp.WorldUp);
				Movement.AddDeltaWithCustomVelocity(DeltaToLocation, FlatVelocity);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMove(Movement);
			DragonComp.RequestLocomotionDragonAndPlayer(TeenDragonLocomotionTags::TeenDragonLedgeDown);
		}
	}

	TOptional<FTeenDragonLedgeDownParams> TraceForLedgeDown() const
	{
		TOptional<FTeenDragonLedgeDownParams> Params;
		
		auto TemporalLog = TEMPORAL_LOG(Player, "Teen Dragon Ledge Down");
		FHazeTraceShape PlayerShape = FHazeTraceShape::MakeFromComponent(Player.CapsuleComponent);

		// First check if we have a blocking wall in front of us
		FHazeTraceSettings ForwardTrace;
		ForwardTrace.TraceWithPlayer(Player);
		FVector LocationWithUpOffset = Player.ActorLocation + Player.ActorUpVector * 100;
		auto ForwardHit = ForwardTrace.QueryTraceSingle(LocationWithUpOffset, LocationWithUpOffset + Player.ActorForwardVector * Settings.LedgeDownGroundTraceForwardOffset);
		TemporalLog.HitResults("Forward Trace Hit", ForwardHit, PlayerShape);
		if (ForwardHit.bBlockingHit)
			return Params;

		FHazeTraceSettings DownTrace;
		DownTrace.UseLine();
		DownTrace.TraceWithPlayerProfile(Player);
		FVector DownTraceEnd = Player.ActorLocation
			+ Player.ActorForwardVector * Settings.LedgeDownGroundTraceForwardOffset
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
		if(AngleToUp < 70.0)
			return Params;	

		// IDK what would cause this
		if(!WallTraceHit.bBlockingHit)
			return Params;

		// Probably not at an edge
		if(WallTraceHit.bStartPenetrating)
			return Params;

		FHazeTraceSettings GroundVerificationTrace;
		GroundVerificationTrace.UseLine();
		GroundVerificationTrace.TraceWithPlayerProfile(Player);

		const FVector TraceUpDir = Player.ActorUpVector; 
		const FVector TraceForwardDir = WallTraceHit.Normal.ConstrainToPlane(FVector::UpVector).GetSafeNormal();

		FVector GroundVerificationStart = Player.ActorLocation
			+ TraceForwardDir * (Player.CapsuleComponent.ScaledCapsuleRadius + Settings.DownGroundTraceForwardOffset);
		FVector GroundVerificationEnd = GroundVerificationStart 
			- TraceUpDir * Settings.DownGroundTraceMaxDownDistance; 
		auto GroundVerificationHit = GroundVerificationTrace.QueryTraceSingle(GroundVerificationStart, GroundVerificationEnd);
		auto GroundVerificationPage = TemporalLog.Page("Ground Verification");
		GroundVerificationPage.HitResults("Hit", GroundVerificationHit, FHazeTraceShape::MakeLine());

		// Invalid hit
		if(!GroundVerificationHit.IsValidBlockingHit())
			return Params;

		const FVector GroundVerificationDeltaToHit = GroundVerificationHit.ImpactPoint - GroundVerificationStart;
		const float GroundVerificationHitDownDistance = GroundVerificationDeltaToHit.DotProduct(-TraceUpDir);
		GroundVerificationPage
			.DirectionalArrow("Delta To Hit", GroundVerificationStart, GroundVerificationDeltaToHit, 10, 4000, FLinearColor::White)
			.Sphere("Ground Verification Start", GroundVerificationStart, 50, FLinearColor::Black, 20)
			.Sphere("Ground Verification End", GroundVerificationEnd, 50, FLinearColor::White, 20)
			.Value("Hit Downwards Distance", GroundVerificationHitDownDistance)
		;

		// Not far down enough
		if(GroundVerificationHitDownDistance < Settings.DownGroundTraceMinDownDistance)
			return Params;

		FHazeTraceSettings GroundWidthTrace;
		GroundWidthTrace.UseShape(PlayerShape);
		GroundWidthTrace.TraceWithPlayerProfile(Player);

		const FVector GroundWidthStart = Player.ActorLocation
			+ TraceForwardDir * (Player.CapsuleComponent.ScaledCapsuleRadius + Settings.DownGroundTraceForwardOffset);
		const FVector GroundWidthEnd = GroundWidthStart 
			- TraceUpDir * Settings.DownGroundTraceMaxDownDistance;

		auto GroundWidthTraceHit = GroundWidthTrace.QueryTraceSingle(GroundWidthStart, GroundWidthEnd);

		auto GroundWidthPage = TemporalLog.Page("Ground Width");
		GroundWidthPage
			.Sphere("Ground Width Start", GroundWidthStart, 50, FLinearColor::Black, 20)
			.Sphere("Ground Width End", GroundWidthEnd, 50, FLinearColor::White, 20)
			.HitResults("Ground Width Trace Hits", GroundWidthTraceHit, PlayerShape)
		;

		if(!GroundWidthTraceHit.bBlockingHit)
			return Params;

		if(!GroundWidthTraceHit.IsValidBlockingHit())
			return Params;

		const FVector DeltaToWidthHit = GroundWidthTraceHit.ImpactPoint - GroundVerificationStart; 
		const float WidthHitDownDistance = DeltaToWidthHit.DotProduct(-Player.ActorUpVector);

		GroundWidthPage
			.DirectionalArrow(f"Hit {GroundWidthTraceHit.Actor.Name} : Delta to Hit", GroundVerificationStart, DeltaToWidthHit, 10, 4000, FLinearColor::Black)
			.Value(f"Hit {GroundWidthTraceHit.Actor.Name} : Hit Down Distance", WidthHitDownDistance)
		;

		// Hit something else on the way down
		if(!Math::IsNearlyEqual(WidthHitDownDistance, GroundVerificationHitDownDistance, 50))
			return Params;

		FVector TargetLocation = GroundWidthTraceHit.ImpactPoint;

		FTeenDragonLedgeDownParams LedgeDownParams;
		LedgeDownParams.LedgeDownComponent = MoveComp.GroundContact.Component;
		LedgeDownParams.TargetRelativeLocation = TargetLocation - LedgeDownParams.LedgeDownComponent.WorldLocation;
		FVector DirToTargetLocation = (TargetLocation - Player.ActorLocation).ConstrainToPlane(TraceUpDir).GetSafeNormal();
		LedgeDownParams.TargetRelativeRotation = FRotator::MakeFromXZ(DirToTargetLocation, TraceUpDir) - LedgeDownParams.LedgeDownComponent.WorldRotation;

		Params.Set(LedgeDownParams);

		return Params;
	}
}