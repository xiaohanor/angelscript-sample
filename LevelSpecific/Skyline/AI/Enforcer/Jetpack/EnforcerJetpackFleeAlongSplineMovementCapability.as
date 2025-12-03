struct FEnforcerJetpackFleeAlongSplineMovementParams
{
	UHazeSplineComponent Spline;
}

class UEnforcerJetpackFleeAlongSplineMovementCapability : UHazeCapability
{	
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 20;
	default DebugCategory = CapabilityTags::Movement;

	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIDestinationComponent DestinationComp;
	UHazeCrumbSyncedActorPositionComponent CrumbMotionComp;
	UBasicAIFleeingComponent FleeComp;
	USkylineEnforcerSettings Settings;
	UTeleportingMovementData Movement;
	FVector PrevLocation;
	
	bool bAtSpline = false;
	UHazeSplineComponent CurSpline;
	FVector MoveToSplineStart;
	FVector MoveToSplineStartControl;
	FVector MoveToSplineEndControl;
	float MoveToSplineDistance;
	float MoveToSplineAlpha;

	FHazeAcceleratedFloat AccSpeed;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DestinationComp = UBasicAIDestinationComponent::GetOrCreate(Owner);
		CrumbMotionComp = UHazeCrumbSyncedActorPositionComponent::GetOrCreate(Owner); // This has to be created before MoveComp runs BeginPlay
		MoveComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);
		FleeComp = UBasicAIFleeingComponent::Get(Owner);
		Settings = USkylineEnforcerSettings::GetSettings(Owner);
		Movement = MoveComp.SetupTeleportingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FEnforcerJetpackFleeAlongSplineMovementParams& OutParams) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		if (!FleeComp.bWantsToFlee)
			return false;
		if (DestinationComp.FollowSpline == nullptr)
			return false;
		OutParams.Spline = DestinationComp.FollowSpline;
        return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;
		if (!FleeComp.bWantsToFlee)
			return true;
        return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FEnforcerJetpackFleeAlongSplineMovementParams Params)
	{
		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);
		PrevLocation = Owner.ActorLocation;
		bAtSpline = false;
		CurSpline = Params.Spline;

		// Launch upwards along bezier curve to start of spline, then follow spline
		AccSpeed.SnapTo(MoveComp.Velocity.DotProduct(Owner.ActorUpVector));
		DestinationComp.FollowSplinePosition = CurSpline.GetSplinePositionAtSplineDistance(0.0); 
		MoveToSplineAlpha = 0.0;
		MoveToSplineStart = Owner.ActorLocation;
		MoveToSplineStartControl = MoveToSplineStart + Owner.ActorUpVector * Settings.FleeSpeed;
		MoveToSplineEndControl = DestinationComp.FollowSplinePosition.WorldLocation - DestinationComp.FollowSplinePosition.WorldForwardVector * Settings.FleeSpeed;
		MoveToSplineDistance = BezierCurve::GetLength_2CP(MoveToSplineStart, MoveToSplineStartControl, MoveToSplineEndControl, DestinationComp.FollowSplinePosition.WorldLocation);

		UMovementGravitySettings::SetGravityScale(Owner, 0.0, this, EHazeSettingsPriority::Defaults);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DestinationComp.FollowSplinePosition = FSplinePosition();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(!MoveComp.PrepareMove(Movement))
			return;

		if (DeltaTime < SMALL_NUMBER)
			return;

		if(HasControl())
		{
			if (!bAtSpline)
				ComposeMoveToSpline(DeltaTime);
			else 
				ComposeMoveAlongSpline(DeltaTime);
		}
		else
		{
			// Since we normally don't want to replicate velocity, we use move since last frame instead.
			// This can fluctuate wildly, introduce smoothing/velocity replication if necessary
			FVector Velocity = (Owner.ActorLocation - PrevLocation) / DeltaTime;
			Movement.ApplyCrumbSyncedAirMovementWithCustomVelocity(Velocity);
			PrevLocation = Owner.ActorLocation;
		}

		MoveComp.ApplyMove(Movement);
	}

	void ComposeMoveAlongSpline(float DeltaTime)
	{
		float Speed = AccSpeed.AccelerateTo(Settings.FleeSpeed, 3.0, DeltaTime);
		DestinationComp.FollowSplinePosition.Move(Speed * DeltaTime);
		FVector NewLoc = DestinationComp.FollowSplinePosition.WorldLocation;
		Movement.AddDeltaFromMoveToPositionWithCustomVelocity(NewLoc, DestinationComp.FollowSplinePosition.WorldForwardVector * Speed);
		Movement.SetRotation(MoveComp.AccRotation.AccelerateTo(DestinationComp.FollowSplinePosition.WorldRotation.Rotator(), Settings.FleeTurnDuration, DeltaTime));

#if EDITOR
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugLine(NewLoc, NewLoc + DestinationComp.FollowSplinePosition.WorldUpVector * 400.0, FLinearColor::DPink, 5.0);		
			CurSpline.DrawDebug(200, FLinearColor::Purple, 5.0);
		}
#endif
	}

	void ComposeMoveToSpline(float DeltaTime)
	{
		MoveToSplineDistance = BezierCurve::GetLength_2CP(MoveToSplineStart, MoveToSplineStartControl, MoveToSplineEndControl, DestinationComp.FollowSplinePosition.WorldLocation);
		float Speed = AccSpeed.AccelerateTo(Settings.FleeSpeed, 0.1, DeltaTime);
		MoveToSplineAlpha += (Speed * DeltaTime / Math::Max(0.1, MoveToSplineDistance));
		FVector NewLoc = BezierCurve::GetLocation_2CP_ConstantSpeed(MoveToSplineStart, MoveToSplineStartControl, MoveToSplineEndControl, DestinationComp.FollowSplinePosition.WorldLocation, MoveToSplineAlpha);
		Movement.AddDeltaFromMoveToPositionWithCustomVelocity(NewLoc, (NewLoc - Owner.ActorLocation) / Math::Max(0.01, DeltaTime));

		Movement.SetRotation(MoveComp.AccRotation.AccelerateTo((DestinationComp.FollowSplinePosition.WorldLocation - Owner.ActorLocation).Rotation(), Settings.FleeTurnDuration, DeltaTime));				

		if (MoveToSplineAlpha > 1.0)
			bAtSpline = true;

#if EDITOR
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			FVector PrevLoc = MoveToSplineStart;
			const float Interval = 0.01;
			for (float f = Interval; f < 1.0 + SMALL_NUMBER; f += Interval)
			{
				FVector Loc = BezierCurve::GetLocation_2CP(MoveToSplineStart, MoveToSplineStartControl, MoveToSplineEndControl, DestinationComp.FollowSplinePosition.WorldLocation, f);
				Debug::DrawDebugLine(PrevLoc, Loc, FLinearColor::Yellow, 5.0);
				PrevLoc = Loc;
			}
			CurSpline.DrawDebug(200, FLinearColor::Purple, 5.0);
		}
#endif
	}
}
