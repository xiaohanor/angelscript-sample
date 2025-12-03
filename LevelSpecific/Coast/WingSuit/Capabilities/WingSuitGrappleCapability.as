class UWingSuitGrappleCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"Wingsuit");
	default CapabilityTags.Add(n"WingsuitMovement");
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default DebugCategory = n"Wingsuit";

	UPlayerMovementComponent MoveComp;
	UWingSuitPlayerComponent WingSuitComp;
	UPlayerTargetablesComponent TargetablesComp;
	UPlayerGrappleComponent GrappleComp;
	USweepingMovementData Movement;
	UWingSuitSettings Settings;

	UWingSuitGrapplePointComponent CurrentGrapplePoint;
	bool bMoveDone = false;
	float CurrentSpeed;
	bool bGrappleVisible = false;
	float MaxSpeed;
	FVector GrappleCurrentVelocity;
	FVector OldGrappleLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GrappleComp = UPlayerGrappleComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		WingSuitComp = UWingSuitPlayerComponent::Get(Player);
		Movement = MoveComp.SetupSweepingMovementData();
		Settings = UWingSuitSettings::GetSettings(Player);
		TargetablesComp = UPlayerTargetablesComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FWingSuitGrappleActivatedParams& Params) const
	{
		if(!WingSuitComp.bWingsuitActive)
			return false;

		auto GrapplePoint = TargetablesComp.GetPrimaryTarget(UWingSuitGrapplePointComponent);

		if(GrapplePoint == nullptr)
			return false;

		if(!WasActionStarted(ActionNames::ContextualMovement))
			return false;

		Params.TargetGrapplePoint = GrapplePoint;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!WingSuitComp.bWingsuitActive)
			return true;

		if(bMoveDone)
			return true;

		if(CurrentGrapplePoint.bExitGrappleWhenPlayerBelow && Player.ActorLocation.Z < CurrentGrapplePoint.WorldLocation.Z)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FWingSuitGrappleActivatedParams Params)
	{
		UMovementGravitySettings::SetTerminalVelocity(Player, -1.0, this);
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Apply(false, this);

		WingSuitComp.WingSuit.PointOfInterestLocation.AttachToComponent(Player.RootComponent, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);

		CurrentGrapplePoint = Params.TargetGrapplePoint;
		bMoveDone = false;
		bGrappleVisible = false;
		CurrentSpeed = MoveComp.Velocity.Size();
		MaxSpeed = Math::Max(Settings.GrappleMaxSpeed, CurrentSpeed);
		WingSuitComp.AnimData.bIsGrappling = true;

		GrappleCurrentVelocity = FVector::ZeroVector;
		OldGrappleLocation = CurrentGrapplePoint.WorldLocation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UMovementGravitySettings::ClearTerminalVelocity(Player, this);
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Clear(this);

		WingSuitComp.WingSuit.PointOfInterestLocation.AttachToComponent(WingSuitComp.WingSuit.RootComponent, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);

		GrappleComp.Grapple.AttachToActor(Player, n"LeftAttach", EAttachmentRule::SnapToTarget);
		GrappleComp.Grapple.SetActorHiddenInGame(true);
		WingSuitComp.AnimData.bIsGrappling = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		GrappleCurrentVelocity = (CurrentGrapplePoint.WorldLocation - OldGrappleLocation) / DeltaTime;
		OldGrappleLocation = CurrentGrapplePoint.WorldLocation;

		//FVector GrappleExpectedLocation = GetGrapplePointExpectedLocation();

		if(!bGrappleVisible && ActiveDuration >= Settings.GrappleAnticipationDelay)
		{
			GrappleComp.Grapple.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);

			GrappleComp.Grapple.SetActorHiddenInGame(false);
			GrappleComp.Grapple.Tense = 1.35;
			GrappleComp.Grapple.SetActorRotation((CurrentGrapplePoint.WorldLocation - GrappleComp.Grapple.ActorLocation).Rotation());
			bGrappleVisible = true;
		}

		FVector CurrentUpVector = FVector::UpVector;
		const FVector AxisToRotateAround = WingSuitComp.SyncedHorizontalMovementOrientation.Value.RightVector;
		CurrentUpVector = CurrentUpVector.RotateAngleAxis(WingSuitComp.CurrentPitchOffset, AxisToRotateAround);

		if(MoveComp.PrepareMove(Movement, CurrentUpVector))
		{
			if(HasControl())
			{
				const float MaxDelta = (CurrentGrapplePoint.WorldLocation - Player.ActorLocation).Size();
				float CurrentDelta = CurrentSpeed * DeltaTime;

				if(bGrappleVisible)
					SetGrappleHookLocation();

				if(CurrentDelta >= MaxDelta)
				{
					CurrentDelta = MaxDelta;
					bMoveDone = true;
				}
				
				const FVector Direction = (CurrentGrapplePoint.WorldLocation - Player.ActorLocation).GetSafeNormal();
				Movement.AddDeltaWithCustomVelocity(Direction * CurrentDelta, Direction * CurrentSpeed);
				//Movement.SetRotation(FQuat::MakeFromXZ(Direction, FVector::UpVector));

				if(ActiveDuration > Settings.GrappleAnticipationDelay + Settings.GrappleEnterDuration)
				{
					CurrentSpeed += Settings.GrappleAcceleration * DeltaTime;
					CurrentSpeed = Math::Min(CurrentSpeed, MaxSpeed);
				}
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"WingSuit");
		}
	}

	FVector GetGrapplePointExpectedLocation()
	{
		float SecsToReachGrapplePoint = GetSecsToReachGrapplePoint();
		return CurrentGrapplePoint.WorldLocation + GrappleCurrentVelocity * SecsToReachGrapplePoint;
	}

	float GetSecsToReachGrapplePoint()
	{
		float GrappleDistance = (CurrentGrapplePoint.WorldLocation - Player.ActorLocation).Size();

		// If at max speed already (or zero acceleration), we don't have to deal with acceleration.
		if(Math::IsNearlyEqual(CurrentSpeed, MaxSpeed) || Math::IsNearlyZero(Settings.GrappleAcceleration))
		{
			if(CurrentSpeed == 0.0)
				return 0.0;

			return GrappleDistance / CurrentSpeed;
		}

		float SecsUntilAcceleration = Math::Max(0.0, (Settings.GrappleAnticipationDelay + Settings.GrappleEnterDuration) - ActiveDuration);
		float DistanceCoveredBeforeAcceleration = CurrentSpeed * SecsUntilAcceleration;

		// We'll reach point before starting to accelerate so we don't have to deal with acceleration.
		if(DistanceCoveredBeforeAcceleration >= GrappleDistance && CurrentSpeed != 0.0)
		{
			return GrappleDistance / CurrentSpeed;
		}

		float RemainingDistance = GrappleDistance - DistanceCoveredBeforeAcceleration;

		// Solve how long it will take to travel a specified distance with initial velocity and acceleration
		// (u = initialVel, t = time, a = acceleration, s = displacement)
		// 0.5at^2 + ut − s = 0
		// solve for t using quadratic formula
		// t = (-u +- sqrt(u^2 - 2as)) / a

		float Sqrt = Math::Sqrt(Math::Square(CurrentSpeed) - (2 * Settings.GrappleAcceleration * RemainingDistance));
		float AnswerOne = (-CurrentSpeed + Sqrt) / Settings.GrappleAcceleration;
		float AnswerTwo = (-CurrentSpeed - Sqrt) / Settings.GrappleAcceleration;
		PrintToScreen(f"{AnswerOne=}, {AnswerTwo=}");
		return SecsUntilAcceleration + (AnswerOne >= 0.0 ? AnswerOne : AnswerTwo);
	}

	void SetGrappleHookLocation()
	{
		float Alpha = (ActiveDuration - Settings.GrappleAnticipationDelay) / Settings.GrappleEnterDuration;
		Alpha = Math::Clamp(Alpha, 0.0, 1.0);
		FVector RopeLocation = Math::Lerp(CurrentGrapplePoint.WorldLocation, Player.Mesh.GetSocketLocation(n"LeftAttach"), Alpha);
		GrappleComp.Grapple.SetActorLocation(RopeLocation);
		float NewTense = Math::Lerp(0.15, 2.15, Alpha);
		GrappleComp.Grapple.Tense = NewTense;
	}
}

struct FWingSuitGrappleActivatedParams
{
	UWingSuitGrapplePointComponent TargetGrapplePoint;
}