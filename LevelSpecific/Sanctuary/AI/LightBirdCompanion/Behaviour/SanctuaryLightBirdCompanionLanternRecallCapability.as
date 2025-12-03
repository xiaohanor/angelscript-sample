class USanctuaryLightBirdCompanionLanternRecallCapability : UHazeCapability
{
	default CapabilityTags.Add(BasicAITags::Behaviour);
	default CapabilityTags.Add(LightBird::Tags::LightBird);
	default CapabilityTags.Add(LightBird::Tags::LightBirdLantern);

	default TickGroup = EHazeTickGroup::BeforeMovement; 
	default TickGroupOrder = 90; // Before lanternattached

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
		if (CompanionComp.UserComp.State != ELightBirdState::Lantern)
			return false;
		if (CompanionComp.State == ELightBirdCompanionState::LanternAttached)
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
		if (CompanionComp.State != ELightBirdCompanionState::LanternRecall)
			return true;
		if (CompanionComp.UserComp.State != ELightBirdState::Lantern)
			return true;
		if (Owner.ActorLocation.IsWithinDist(Destination, 0.1))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CompanionComp.State = ELightBirdCompanionState::LanternRecall;

		// We must detach before commencing move
		CompanionComp.Detach();

		StartLocation = Owner.ActorLocation;

		Destination = CompanionComp.Player.Mesh.GetSocketLocation(Settings.LanternSocket);
		float Distance = Math::Max(Destination.Distance(StartLocation), 1.0);

		StartTangent = Owner.ActorVelocity.GetClampedToMaxSize(Distance * 0.1);

		EndTangent = (CompanionComp.Player.ActorForwardVector * 0.7 - CompanionComp.Player.ActorUpVector * 0.3) * Distance * 0.1;

		Speed.SnapTo(Owner.ActorVelocity.Size());
		CurrentDistance = 0.0;

		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);

		AnimComp.RequestFeature(LightBirdCompanionAnimTags::LanternRecall, EBasicBehaviourPriority::Medium, this);

		ULightBirdEventHandler::Trigger_LanternRecallStarted(Owner);
		ULightBirdEventHandler::Trigger_LanternRecallStarted(CompanionComp.Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (CompanionComp.UserComp.State == ELightBirdState::Lantern)
			CompanionComp.State = ELightBirdCompanionState::LanternAttached; 
		else 
			CompanionComp.State = ELightBirdCompanionState::Follow; 
		CompanionComp.Illuminators.RemoveSingleSwap(this);

		AnimComp.ClearFeature(this);

		ULightBirdEventHandler::Trigger_LanternRecallStopped(Owner);
		ULightBirdEventHandler::Trigger_LanternRecallStopped(CompanionComp.Player);
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

		if (HasControl() && !CompanionComp.Illuminators.Contains(this) &&
			Owner.ActorLocation.IsWithinDist(Destination, Settings.LanternIlluminateRange))
		{
			CrumbStartIlluminating();			
		}
	}

	void ComposeMovement(float DeltaTime)
	{
		if (DeltaTime == 0.0)
			return;

		Destination = CompanionComp.Player.Mesh.GetSocketLocation(Settings.LanternSocket);
		Speed.AccelerateTo(Settings.LanternReturnSpeed, Settings.LanternReturnAccelerationDuration, DeltaTime);
		CurrentDistance += Speed.Value * DeltaTime;
		FVector StartControl = StartLocation + StartTangent;
		FVector EndControl = Destination - EndTangent;
		float Length = BezierCurve::GetLength_2CP(StartLocation, StartControl, EndControl, Destination);
		float Alpha = Math::Min(1.0, CurrentDistance / Length);
		FVector NewLoc = BezierCurve::GetLocation_2CP_ConstantSpeed(StartLocation, StartControl, EndControl, Destination, Alpha);
		FVector Delta = NewLoc - Owner.ActorLocation;
		Movement.AddDeltaFromMoveToPositionWithCustomVelocity(NewLoc, Delta / DeltaTime);

		// Rotate to match player forward when close, velocity otherwise
		FVector Direction = Delta;
		if (Owner.ActorLocation.IsWithinDist(Destination, 600.0))
			Direction = CompanionComp.Player.ActorForwardVector;
		FRotator Rotation = MoveComp.GetRotationTowardsDirection(Direction, 1.0, DeltaTime);
		Movement.SetRotation(Rotation);

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			float Interval = 0.02;
			FVector PrevLoc = StartLocation;
			for (float DbgAlpha = Interval; DbgAlpha < 1.0; DbgAlpha += Interval)
			{
				FVector CurveLoc = BezierCurve::GetLocation_2CP(StartLocation, StartControl, EndControl, Destination, DbgAlpha);
				Debug::DrawDebugLine(PrevLoc, CurveLoc, FLinearColor::Green, 3.0);
				PrevLoc = CurveLoc;
			} 
		}
#endif		
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartIlluminating()
	{
		CompanionComp.Illuminators.Add(this);
	}
};