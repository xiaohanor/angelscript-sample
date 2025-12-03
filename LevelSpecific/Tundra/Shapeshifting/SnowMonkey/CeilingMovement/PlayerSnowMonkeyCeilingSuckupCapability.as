/** This capability helps the snow monkey by adding an impulse upwards when you jump and just barely miss a climbable ceiling */
class UTundraPlayerSnowMonkeyCeilingSuckupCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(TundraShapeshiftingTags::SnowMonkey);
	default CapabilityTags.Add(TundraShapeshiftingTags::SnowMonkeyCeilingClimb);

	default TickGroup = EHazeTickGroup::InfluenceMovement;
	default TickGroupOrder = 105;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UTundraPlayerShapeshiftingComponent ShapeshiftComp;
	UTundraPlayerSnowMonkeyComponent SnowMonkeyComp;
	UPlayerSwimmingComponent SwimmingComp;
	UPlayerMovementComponent MoveComp;
	USweepingMovementData Movement;
	UPlayerPoleClimbComponent PoleClimbComp;
	UTundraPlayerSnowMonkeySettings Settings;
	bool bMoveDone = false;
	float TimeToReachCeiling;
	FVector StartRelativePoint;
	FVector TargetRelativePoint;
	UPrimitiveComponent RelativeTo;
	TOptional<float> InitialDeltaTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ShapeshiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);
		SnowMonkeyComp = UTundraPlayerSnowMonkeyComponent::Get(Player);
		SwimmingComp = UPlayerSwimmingComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSweepingMovementData();
		Settings = UTundraPlayerSnowMonkeySettings::GetSettings(Player);
		PoleClimbComp = UPlayerPoleClimbComponent::Get(Player);
	}

#if !RELEASE
	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog TemporalLog)
	{
		TemporalLog.Point("Start Point", RelativeTo.WorldTransform.TransformPosition(StartRelativePoint), 15.f, FLinearColor::Red);
		TemporalLog.Point("Target Point", RelativeTo.WorldTransform.TransformPosition(TargetRelativePoint), 15.f, FLinearColor::Green);
		TemporalLog.Sphere("Big Start Point", RelativeTo.WorldTransform.TransformPosition(StartRelativePoint), 50.f, FLinearColor::Red);
		TemporalLog.Sphere("Big Target Point", RelativeTo.WorldTransform.TransformPosition(TargetRelativePoint), 50.0f, FLinearColor::Green);
	}
#endif

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundraPlayerSnowMonkeyCeilingCoyoteActivatedParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
		{
			TemporalLogActivation("We have moved this frame!");
			return false;
		}

		if(!ShapeshiftComp.IsBigShape())
		{
			TemporalLogActivation("We aren't big shape");
			return false;
		}

		if(MoveComp.HasGroundContact())
		{
			TemporalLogActivation("We are grounded");
			return false;
		}

		if(MoveComp.HasCeilingContact())
		{
			TemporalLogActivation("We have ceiling contact");
			return false;
		}

		if(PoleClimbComp.IsClimbing())
		{
			TemporalLogActivation("We are pole climbing");
			return false;
		}

		if(SnowMonkeyComp.bJustCeilingClimbed)
		{
			TemporalLogActivation("We just ceiling climbed");
			return false;
		}

		if(SnowMonkeyComp.bJustSuckedUp)
		{
			TemporalLogActivation("We just sucked up");
			return false;
		}

		if(SwimmingComp.IsSwimming())
		{
			TemporalLogActivation("We are swimming");
			return false;
		}

		if(DeactiveDuration < 0.1)
		{
			TemporalLogActivation("DeactiveDuration < 0.1");
			return false;
		}

		if(SnowMonkeyComp.CurrentAnimationCeilingComponent != nullptr)
		{
			if(!SnowMonkeyComp.CurrentAnimationCeilingComponent.bAllowCoyoteSuckUp)
			{
				TemporalLogActivation("CurrentAnimationCeilingComponent != nullptr but bAllowCoyoteSuckUp == false");
				return false;
			}

			if(!SnowMonkeyComp.CurrentAnimationCeilingComponent.bAllowCoyoteSuckupEvenWithDownwardsVelocity && MoveComp.VerticalSpeed < 0)
			{
				TemporalLogActivation("We are falling");
				return false;
			}

 			Params.ClimbComp = SnowMonkeyComp.CurrentAnimationCeilingComponent;
			TArray<UPrimitiveComponent> Comps;
			Params.ClimbComp.GetClimbableComponents(Comps);
			Params.CollisionComp = Comps[0];

			FTundraPlayerSnowMonkeyCeilingData CeilingData = Params.ClimbComp.GetCeilingData();
			Params.DistanceToCeiling = CeilingData.GetVerticalDistanceToCeiling(Player.ActorLocation + FVector::UpVector * (Player.CapsuleComponent.ScaledCapsuleHalfHeight * 2.0));
			TemporalLogActivation("CurrentAnimationCeilingComponent != nullptr", true);
			return true;
		}
		
		UTundraPlayerSnowMonkeyCeilingClimbComponent ClimbComp;
		UPrimitiveComponent CollisionComp;
		if(!IsCeilingValid(ClimbComp, CollisionComp))
		{
			TemporalLogActivation("Ceiling isn't valid");
			return false;
		}

		if(!ClimbComp.bAllowCoyoteSuckupEvenWithDownwardsVelocity && MoveComp.VerticalSpeed < 0)
		{
			TemporalLogActivation("We are falling");
			return false;
		}

		FTundraPlayerSnowMonkeyCeilingData CeilingData = ClimbComp.GetCeilingData();
		Params.DistanceToCeiling = CeilingData.GetVerticalDistanceToCeiling(Player.ActorLocation + FVector::UpVector * (Player.CapsuleComponent.ScaledCapsuleHalfHeight * 2.0));
		Params.ClimbComp = ClimbComp;
		Params.CollisionComp = CollisionComp;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(bMoveDone)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundraPlayerSnowMonkeyCeilingCoyoteActivatedParams Params)
	{
		SnowMonkeyComp.bIsInCeilingSuckup = true;
		bMoveDone = false;
		InitialDeltaTime.Reset();
		float VerticalSpeed = Player.ActorVerticalVelocity.Size();

		if(VerticalSpeed > 0.0)
			TimeToReachCeiling = Params.DistanceToCeiling / VerticalSpeed;
		else if(VerticalSpeed < 0.0)
			TimeToReachCeiling = Settings.CeilingSuckupMaxEnterTime;
		else
			TimeToReachCeiling = 0.0;
		
		TimeToReachCeiling = Math::Clamp(TimeToReachCeiling, Settings.CeilingSuckupMinEnterTime, Settings.CeilingSuckupMaxEnterTime);
		SnowMonkeyComp.SuckupDuration = TimeToReachCeiling;

		RelativeTo = Params.CollisionComp;
		FTundraPlayerSnowMonkeyCeilingData CeilingData = Params.ClimbComp.GetCeilingData();
		CeilingData.Pushback += 15.0;

		FVector PredictedLocation = Player.ActorLocation + Player.ActorHorizontalVelocity * TimeToReachCeiling;
		FVector ClosestPointOnCeiling = CeilingData.GetClosestPointOnCeiling(PredictedLocation + FVector::UpVector * (Player.CapsuleComponent.ScaledCapsuleHalfHeight * 2.0));
		FVector MovedDownClosestPoint = ClosestPointOnCeiling - FVector::UpVector * (Player.CapsuleComponent.ScaledCapsuleHalfHeight * 2.0);
		FVector ConstrainedTargetPoint;
		CeilingData.ConstrainToCeiling(MovedDownClosestPoint, ConstrainedTargetPoint);

		FHazeTraceSettings Trace = Trace::InitFromPlayer(Player);
		Trace.UseLine();
		Trace.IgnorePlayers();
		FHitResultArray Hits = Trace.QueryTraceMulti(ConstrainedTargetPoint, ConstrainedTargetPoint + (FVector::UpVector * Player.CapsuleComponent.ScaledCapsuleHalfHeight * 4.0));
		FHitResult RelevantHit;
		for(FHitResult Hit : Hits.BlockHits)
		{
			if(Hit.Actor != Params.ClimbComp.Owner)
				continue;

			RelevantHit = Hit;
			break;
		}
		devCheck(RelevantHit.bBlockingHit && RelevantHit.Actor == Params.ClimbComp.Owner, "Didn't hit ceiling in suckup");
		FVector MovedUpPoint = RelevantHit.ImpactPoint;
		FVector MovedDownFinalPoint = MovedUpPoint - FVector::UpVector * (Player.CapsuleComponent.ScaledCapsuleHalfHeight * 2.0);

#if !RELEASE
		TEMPORAL_LOG(this)
			.Value("Vertical Speed", VerticalSpeed)
			.Value("Distance To Ceiling", Params.DistanceToCeiling)
			.Value("Time To Reach Ceiling", TimeToReachCeiling)
			.Point("Predicted Location", PredictedLocation)
			.Point("Closest Point On Ceiling", ClosestPointOnCeiling)
			.Point("Moved Down Closest Point", MovedDownClosestPoint)
			.Point("Constrained Target Point", ConstrainedTargetPoint)
			.Point("Moved Up Point", MovedUpPoint)
			.Point("Moved Down Final Point", MovedDownFinalPoint)
			.HitResults("Move Up Hit", RelevantHit, FHazeTraceShape::MakeLine())
		;
#endif
		TargetRelativePoint = MovedDownFinalPoint;
		StartRelativePoint = Player.ActorLocation;

		TargetRelativePoint = RelativeTo.WorldTransform.InverseTransformPosition(TargetRelativePoint);
		StartRelativePoint = RelativeTo.WorldTransform.InverseTransformPosition(StartRelativePoint);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SnowMonkeyComp.bIsInCeilingSuckup = false;
		SnowMonkeyComp.FrameOfEndSuckUp = Time::FrameNumber;
		SnowMonkeyComp.bJustSuckedUp = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!InitialDeltaTime.IsSet())
			InitialDeltaTime.Set(DeltaTime);

		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				float Alpha = (ActiveDuration + InitialDeltaTime.Value) / TimeToReachCeiling;
				if(Alpha >= 1.0)
				{
					Alpha = 1.0;
					Movement.AddDeltaWithCustomVelocity(FVector::UpVector * 3.0, FVector::ZeroVector);
					bMoveDone = true;
				}

				FVector Point = Math::Lerp(StartRelativePoint, TargetRelativePoint, Alpha);
				Point = RelativeTo.WorldTransform.TransformPosition(Point);

				FVector Delta = Point - Player.ActorLocation;
				Movement.AddDeltaWithCustomVelocity(Delta, FVector::ZeroVector);
				SnowMonkeyComp.SuckUpVelocity = Delta / DeltaTime;
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"SnowMonkeyCeiling");
		}
	}

	void TemporalLogActivation(FString Reason, bool bActivated = false) const
	{
#if !RELEASE
		if(!bActivated)
			TEMPORAL_LOG(this).Value("Not Activated Reason", Reason);
		else
			TEMPORAL_LOG(this).Value("Activated Reason", Reason);
#endif
	}

	bool IsCeilingValid(UTundraPlayerSnowMonkeyCeilingClimbComponent&out ClimbComp, UPrimitiveComponent&out CollisionComp) const
	{
		TArray<FVector> Origins;
		Origins.Add(Player.ActorCenterLocation + FVector::UpVector * (Player.CapsuleComponent.ScaledCapsuleHalfHeight - Player.CapsuleComponent.ScaledCapsuleRadius));
		Origins.Add(Origins[0] + MoveComp.HorizontalVelocity.GetSafeNormal() * Settings.CeilingSuckupMaxHorizontalDistance);

		for(int i = 0; i < Origins.Num(); i++)
		{
			FVector Origin = Origins[i];

			FHazeTraceSettings Trace = Trace::InitFromPrimitiveComponent(Player.CapsuleComponent);
			Trace.UseSphereShape(Player.CapsuleComponent.ScaledCapsuleRadius);
			if(IsDebugActive())
				Trace.DebugDraw(0.5);
			Trace.IgnorePlayers();

			FVector Destination = Origin + FVector::UpVector * Settings.CeilingSuckupMaxVerticalDistance;
			FHitResult Hit = Trace.QueryTraceSingle(Origin, Destination);

#if EDITOR
			TEMPORAL_LOG(this)
			.HitResults(f"IsCeilingValid Hit[{i}]", Hit, Trace.Shape, Trace.ShapeWorldOffset)
			;
#endif

			if(Hit.bStartPenetrating)
				return false;

			if(!Hit.bBlockingHit)
				continue;

			ClimbComp = UTundraPlayerSnowMonkeyCeilingClimbComponent::Get(Hit.Actor);
			if(ClimbComp == nullptr)
				continue;

			if(ClimbComp.IsDisabled())
				continue;

			if(!ClimbComp.ComponentIsClimbable(Hit.Component))
				continue;

			FTundraPlayerSnowMonkeyCeilingData Data = ClimbComp.GetCeilingData();
			if(!Data.IsPointWithinCeiling(Hit.ImpactPoint))
				continue;

			if(!ClimbComp.bAllowCoyoteSuckUp)
				continue;

			CollisionComp = Hit.Component;
			return true;
		}

		return false;
	}
}
