class USanctuaryLightBirdCompanionLaunchStartCapability : UHazeCapability
{
	default CapabilityTags.Add(BasicAITags::Behaviour);
	default CapabilityTags.Add(LightBird::Tags::LightBird);
	default CapabilityTags.Add(LightBird::Tags::LightBirdRelease);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 80; // Should be able to abort lantern/launchattached

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USanctuaryLightBirdCompanionComponent CompanionComp;
	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIAnimationComponent AnimComp;
	USanctuaryLightBirdCompanionSettings Settings;
	UTeleportingMovementData Movement;
	
	FVector StartLocation; 
	FVector StartTangent;
	FVector EndTangent;
	FVector Destination;

	FHazeAcceleratedFloat Speed;
	float CurrentDistance;
	float CurveLength;

	bool bAttached = false;
	FHazeAcceleratedVector AccRelativeLocation;
	FHazeAcceleratedRotator AccRelativeRotation;

	float LaunchStartCooldown = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CompanionComp = USanctuaryLightBirdCompanionComponent::GetOrCreate(Owner); 
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		Settings = USanctuaryLightBirdCompanionSettings::GetSettings(Owner); 
		Movement = MoveComp.SetupTeleportingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		if (!UserWantsToLaunch())
			return false;
		if ((CompanionComp.State == ELightBirdCompanionState::Launched) && (CompanionComp.UserComp.LastAimStartTime < LaunchStartCooldown))
			return false; // Already launching from this aim
		if ((CompanionComp.State == ELightBirdCompanionState::LaunchAttached) && 
			(CompanionComp.UserComp.AttachedTargetData.SceneComponent == Owner.RootComponent.AttachParent))
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
		if (CompanionComp.State != ELightBirdCompanionState::LaunchStart)
			return true;
		if ((CompanionComp.UserComp.State != ELightBirdState::Aiming) && (ActiveDuration > Settings.LaunchStartMinDuration))
			return true;
		return false;
	}

	bool UserWantsToLaunch() const
	{
		// Start launch when aiming...
		if (CompanionComp.UserComp.State == ELightBirdState::Aiming)
			return true;
		// ...or transitioned to attached (when we have a target) or hover (when we do not) from aiming
		if (CompanionComp.UserComp.PreviousState == ELightBirdState::Aiming)
		{
			if ((CompanionComp.UserComp.State == ELightBirdState::Attached) || (CompanionComp.UserComp.State == ELightBirdState::Hover)) 
				return true;
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CompanionComp.State = ELightBirdCompanionState::LaunchStart;
		LaunchStartCooldown = CompanionComp.UserComp.LastAimStartTime + SMALL_NUMBER;

		// We must detach before commencing move
		CompanionComp.Detach();
		bAttached = false;

		StartLocation = Owner.ActorLocation;

		Destination = GetDestination();
		float Distance = Math::Max(Destination.Distance(StartLocation), 1.0);

		StartTangent = Owner.ActorVelocity.GetClampedToMaxSize(Distance * 0.5);

		EndTangent = (CompanionComp.Player.ActorForwardVector * 0.7 - CompanionComp.Player.ActorUpVector * 0.3) * Math::Min(Distance * 0.5, 500.0);

		Speed.SnapTo(Owner.ActorVelocity.Size());
		CurrentDistance = 0.0;
		CurveLength = Distance; 

		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);

		AnimComp.RequestFeature(LightBirdCompanionAnimTags::LaunchStart, EBasicBehaviourPriority::Medium, this);

		ULightBirdEventHandler::Trigger_ReleaseStarted(Owner);
		ULightBirdEventHandler::Trigger_ReleaseStarted(CompanionComp.Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Up, up and away!
		if (CompanionComp.State == ELightBirdCompanionState::LaunchStart)
			CompanionComp.State = ELightBirdCompanionState::Launched;

		AnimComp.ClearFeature(this);

		ULightBirdEventHandler::Trigger_ReleaseStopped(Owner);
		ULightBirdEventHandler::Trigger_ReleaseStopped(CompanionComp.Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl() && ShouldAttachToUser())
			CrumbAttachToUser();

		if (bAttached)
		{	
			// Local movement
			Owner.SetActorVelocity(CompanionComp.Player.ActorVelocity + CompanionComp.PlayerGroundVelocity.Value);
			AccRelativeLocation.AccelerateTo(Settings.LaunchStartOffset, 1.0, DeltaTime);
			AccRelativeRotation.AccelerateTo(FRotator::ZeroRotator, Settings.LaunchStartHeldTurnDuration, DeltaTime);
			Owner.SetActorRelativeLocation(AccRelativeLocation.Value);
			Owner.SetActorRelativeRotation(AccRelativeRotation.Value);
			return;
		}

		// Crumbed regular movement
		if(!MoveComp.PrepareMove(Movement))
			return;

		if(HasControl())
			ComposeMovement(DeltaTime);
		else
			Movement.ApplyCrumbSyncedAirMovement();

		MoveComp.ApplyMove(Movement);
	}

	FVector GetDestination() const
	{
		FTransform Transform = CompanionComp.Player.Mesh.GetSocketTransform(Settings.LaunchStartSocket);
		return Transform.TransformPositionNoScale(Settings.LaunchStartOffset);
	}

	bool ShouldAttachToUser()
	{
		if (bAttached)
			return false; // Already attached
		if (ActiveDuration < 0.2)
			return false;
		if (CurrentDistance < CurveLength - 10.0)
			return false;
		return true;
	}

	UFUNCTION(CrumbFunction)
	void CrumbAttachToUser()
	{
		bAttached = true;
		CompanionComp.Attach(CompanionComp.Player.Mesh, Settings.LaunchStartSocket);
		AccRelativeLocation.SnapTo(Owner.ActorRelativeLocation);
		AccRelativeRotation.SnapTo(Owner.ActorRelativeRotation);

		AnimComp.RequestFeature(LightBirdCompanionAnimTags::LaunchStartAttach, EBasicBehaviourPriority::Medium, this);
	}

	void ComposeMovement(float DeltaTime)
	{
		Destination = GetDestination();
		FVector OwnLoc = Owner.ActorLocation;

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