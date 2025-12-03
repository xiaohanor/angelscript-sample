class USanctuaryDarkPortalCompanionLaunchStartCapability : UHazeCapability
{
	default CapabilityTags.Add(BasicAITags::Behaviour);
	default CapabilityTags.Add(DarkPortal::Tags::DarkPortal);
	default CapabilityTags.Add(DarkPortal::Tags::DarkPortalLaunch);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 80; // Should be able to abort lantern/launchattached

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USanctuaryDarkPortalCompanionComponent CompanionComp;
	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIAnimationComponent AnimComp;
	UPlayerAimingComponent UserAimComp;	
	USanctuaryDarkPortalCompanionSettings Settings;
	UTeleportingMovementData Movement;
	
	FVector StartLocation; 
	FVector StartTangent;
	FVector EndTangent;
	FVector Destination;

	FHazeAcceleratedFloat Speed;
	float CurrentDistance;
	float CurveLength;

	bool bAtUser = false;
	FHazeAcceleratedVector AccWorldLocation;
	FHazeAcceleratedRotator AccWorldRotation;
	FHazeAcceleratedFloat AccClampFactor;

	float LaunchStartCooldown = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CompanionComp = USanctuaryDarkPortalCompanionComponent::GetOrCreate(Owner); 
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		UserAimComp = UPlayerAimingComponent::Get(Game::Zoe);
		Settings = USanctuaryDarkPortalCompanionSettings::GetSettings(Owner); 
		Movement = MoveComp.SetupTeleportingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		if (!UserAimComp.IsAiming(CompanionComp.UserComp))
			return false;
		if ((CompanionComp.State == EDarkPortalCompanionState::Launched) && (CompanionComp.UserComp.LastAimStartTime < LaunchStartCooldown))
			return false; // Already launching from this aim	
		if ((CompanionComp.State == EDarkPortalCompanionState::AtPortal) && 
			(CompanionComp.UserComp.Portal == Owner.RootComponent.AttachParent.Owner))
			return false; // Already attached to this	
		// Skip any already handled launches (i.e. when we aim and release without a target)
		if (CompanionComp.UserComp.LastAimStartTime < LaunchStartCooldown)
			return false;
		// Skip if investigating something which ignores player control
		if (CompanionComp.InvestigationDestination.Get().bOverridePlayerControl)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;
		if (!UserAimComp.IsAiming(CompanionComp.UserComp) && (ActiveDuration > Settings.LaunchStartMinDuration))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CompanionComp.State = EDarkPortalCompanionState::LaunchStart;
		LaunchStartCooldown = CompanionComp.UserComp.LastAimStartTime + SMALL_NUMBER;

		// We must detach before commencing move
		CompanionComp.Detach();
		bAtUser = false;

		StartLocation = Owner.ActorLocation;

		Destination = GetDestination();
		float Distance = Math::Max(Destination.Distance(StartLocation), 1.0);

		StartTangent = Owner.ActorVelocity.GetClampedToMaxSize(Distance * 0.5);

		EndTangent = (CompanionComp.Player.ActorForwardVector * 0.7 - CompanionComp.Player.ActorUpVector * 0.3) * Math::Min(Distance * 0.5, 500.0);

		Speed.SnapTo(Owner.ActorVelocity.Size());
		CurrentDistance = 0.0;
		CurveLength = Distance; 

		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);

		AnimComp.RequestFeature(DarkPortalCompanionAnimTags::LaunchStart, EBasicBehaviourPriority::Medium, this);

		UDarkPortalEventHandler::Trigger_CompanionLaunchAnticipationStarted(Owner);
		UDarkPortalEventHandler::Trigger_CompanionLaunchAnticipationStarted(CompanionComp.Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Up, up and away!
		if (CompanionComp.State == EDarkPortalCompanionState::LaunchStart)
			CompanionComp.State = EDarkPortalCompanionState::Launched;

		AnimComp.ClearFeature(this);

		UDarkPortalEventHandler::Trigger_CompanionLaunchAnticipationStopped(Owner);
		UDarkPortalEventHandler::Trigger_CompanionLaunchAnticipationStopped(CompanionComp.Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl() && HasReachedUser())
			CrumbReachUser();

		// Crumbed regular movement
		if(!MoveComp.PrepareMove(Movement))
			return;

		if (HasControl() && HasReachedUser())
			CrumbReachUser();

		if(HasControl())
			ComposeMovement(DeltaTime);
		else
			Movement.ApplyCrumbSyncedAirMovement();

		MoveComp.ApplyMove(Movement);
	}

	FVector GetDestination() const
	{
		FTransform Transform;
		Transform.Location = CompanionComp.Player.Mesh.GetSocketLocation(Settings.LaunchStartSocket);
		Transform.Rotation = FQuat::MakeFromZX(CompanionComp.Player.ActorUpVector, CompanionComp.Player.ViewRotation.ForwardVector);
		return Transform.TransformPositionNoScale(Settings.LaunchStartOffset);
	}

	bool HasReachedUser()
	{
		if (bAtUser)
			return false; // Already attached
		if (ActiveDuration < 0.2)
			return false;
		if (CurrentDistance < CurveLength - 10.0)
			return false;
		return true;
	}

	UFUNCTION(CrumbFunction)
	void CrumbReachUser()
	{
		// Networked so we trigger animation on both sides, could easily be approximated without crumb function.
		bAtUser = true;
		AccWorldLocation.SnapTo(Owner.ActorLocation, Owner.ActorVelocity);
		AccWorldRotation.SnapTo(Owner.ActorRotation);
		AccClampFactor.SnapTo(1.0);
		AnimComp.RequestFeature(DarkPortalCompanionAnimTags::LaunchStartAttach, EBasicBehaviourPriority::Medium, this);
	}

	void ComposeMovement(float DeltaTime)
	{
		Destination = GetDestination();
		FVector OwnLoc = Owner.ActorLocation;

		if (bAtUser)
		{	
			// Move exactly to wanted offset with lag
			AccWorldLocation.AccelerateTo(GetDestination(), Settings.LaunchStartAtUserFollowDuration, DeltaTime);
			float ClampMod = AccClampFactor.AccelerateTo((CompanionComp.Player.ActorVelocity.IsNearlyZero(100.0) ? 1.0 : 0.0), 0.5, DeltaTime);
			FRotator TargetRotation = CompanionComp.Player.ViewRotation.Vector().ClampInsideCone(CompanionComp.Player.ActorForwardVector, Settings.LaunchStartYawClamp * ClampMod).Rotation();
			TargetRotation.Pitch = Math::Clamp(TargetRotation.Pitch, -Settings.LaunchStartPitchClamp * ClampMod, Settings.LaunchStartPitchClamp * ClampMod);
			AccWorldRotation.AccelerateTo(TargetRotation, Settings.LaunchStartHeldTurnDuration, DeltaTime);
			Movement.AddDelta(AccWorldLocation.Value - Owner.ActorLocation);
			Movement.SetRotation(AccWorldRotation.Value);
			return;
		}

		// Move along curve to get near fast
		float TargetSpeed = Settings.LaunchStartSpeed;
		if (CurrentDistance > CurveLength - 1000.0)
			TargetSpeed = Settings.LaunchStartSpeed * 0.25;
		Speed.AccelerateTo(TargetSpeed, 2.0, DeltaTime);
		CurrentDistance += Speed.Value * DeltaTime;
		FVector StartControl = StartLocation + StartTangent;
		FVector EndControl = Destination - EndTangent;
		CurveLength = BezierCurve::GetLength_2CP(StartLocation, StartControl, EndControl, Destination);
		float Alpha = Math::Min(1.0, CurrentDistance / CurveLength);
		FVector NewLoc = BezierCurve::GetLocation_2CP_ConstantSpeed(StartLocation, StartControl, EndControl, Destination, Alpha);
		FVector Delta = NewLoc - OwnLoc;
		Movement.AddDeltaFromMoveToPositionWithCustomVelocity(NewLoc, Delta / DeltaTime);

		// Align with velocity
		MoveComp.RotateTowardsDirection(Delta, 0.5, DeltaTime, Movement);

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			float Interval = 0.02;
			FVector PrevLoc = StartLocation; 
			for (float DbgAlpha = Interval; DbgAlpha < 1.0; DbgAlpha += Interval)
			{
				FVector CurveLoc = BezierCurve::GetLocation_2CP(StartLocation, StartControl, EndControl, Destination, DbgAlpha);
				Debug::DrawDebugLine(PrevLoc, CurveLoc, FLinearColor::Purple, 3.0);
				PrevLoc = CurveLoc;
			} 
		}
#endif
	}
};