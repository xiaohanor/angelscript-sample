struct FDarkPortalInvestigateParams
{
	USceneComponent TargetComp;
}

class USanctuaryDarkPortalCompanionInvestigateCapability : UHazeCapability
{
	default CapabilityTags.Add(BasicAITags::Behaviour);
	default CapabilityTags.Add(DarkPortal::Tags::DarkPortal);
	default CapabilityTags.Add(DarkPortal::Tags::DarkPortalInvestigate);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 10; // Before all others

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USanctuaryDarkPortalCompanionComponent CompanionComp;
	UBasicAICharacterMovementComponent MoveComp;
	USanctuaryDarkPortalCompanionSettings Settings;
	UTeleportingMovementData Movement;
	UBasicAIAnimationComponent AnimComp; 

	FVector StartLocation; 
	FVector StartTangent;
	FVector EndTangent; 

	FHazeAcceleratedFloat Speed;
	float CurrentDistance;
	FDarkPortalInvestigationDestination Destination;	
	bool bArrived = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CompanionComp = USanctuaryDarkPortalCompanionComponent::GetOrCreate(Owner); 
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		Settings = USanctuaryDarkPortalCompanionSettings::GetSettings(Owner); 
		Movement = MoveComp.SetupTeleportingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FDarkPortalInvestigateParams& OutParams) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		if (!ShouldInvestigate(CompanionComp.InvestigationDestination.Get()))
			return false;
		if (CompanionComp.State == EDarkPortalCompanionState::InvestigatingAttached)
			return false;
		OutParams.TargetComp = CompanionComp.InvestigationDestination.Get().TargetComp;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;
		if (bArrived)
			return true;
		if (CompanionComp.State != EDarkPortalCompanionState::Investigating)
			return true;
		if (CompanionComp.InvestigationDestination.Get() != Destination)
			return true; // Found a new shiny thing or lost the current one
		if (!ShouldInvestigate(Destination))
			return true;
		return false;
	}

	bool ShouldInvestigate(FDarkPortalInvestigationDestination Dest) const
	{
		if (!Dest.IsValid())
			return false;
		if (Dest.bOverridePlayerControl)
			return true;		
		if ((CompanionComp.UserComp.Portal.State != EDarkPortalState::Absorb) && (CompanionComp.UserComp.Portal.State != EDarkPortalState::Recall))
			return false;
		if (!CompanionComp.IsFreeFlying() && (CompanionComp.State != EDarkPortalCompanionState::Investigating))
			return false;	
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FDarkPortalInvestigateParams Params)
	{
		CompanionComp.State = EDarkPortalCompanionState::Investigating;
		bArrived = false;

		// We must detach before commencing move
		CompanionComp.Detach();

		Destination = CompanionComp.InvestigationDestination.Get();
		Destination.TargetComp = Params.TargetComp; // Set component on remote

		if (!Destination.IsValid())
		{
			// Attach target has become invalid after end of launch but before this was activated. 
			// Revert to follow state, then deactivate
			CompanionComp.State = EDarkPortalCompanionState::Follow;
			return;
		}

		float Distance = Math::Max(Destination.Location.Distance(StartLocation), 1.0);
		FVector DestDir = (Destination.Location - StartLocation) / Distance;

		StartLocation = Owner.ActorLocation;
		float MaxSpeed = Math::Min(Distance, 4000.0) * Settings.InvestigationNoise;
		StartTangent = Owner.ActorVelocity.GetClampedToMaxSize(MaxSpeed);

		FVector LandDir = Math::GetRandomHalfConeDirection(DestDir, -CompanionComp.Player.ActorUpVector, Math::DegreesToRadians(60.0 * Settings.InvestigationNoise));
		EndTangent = LandDir * Settings.InvestigationSpeed * Settings.InvestigationNoise;

		Speed.SnapTo(Owner.ActorVelocity.Size());
		CurrentDistance = 0.0;

		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);

		AnimComp.RequestFeature(DarkPortalCompanionAnimTags::Investigate, EBasicBehaviourPriority::Medium, this);		

		UDarkPortalEventHandler::Trigger_OnCompanionInvestigateStarted(Owner);
		UDarkPortalEventHandler::Trigger_OnCompanionInvestigateStarted(CompanionComp.Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (CompanionComp.State == EDarkPortalCompanionState::Investigating)
		{
			// Should we land at target or was this just a fly-by?
			if (Destination.Type == EDarkPortalInvestigationType::Attach)
			{
				CompanionComp.State = EDarkPortalCompanionState::InvestigatingAttached;
			}
			else
			{
				CompanionComp.State = EDarkPortalCompanionState::Follow;

				if (CompanionComp.InvestigationDestination.Get() == Destination)
				{
					float Length = BezierCurve::GetLength_2CP(StartLocation, StartLocation + StartTangent, Destination.Location - EndTangent, Destination.Location);
					if (CurrentDistance > Length * 0.5)
					{
						// Been there, done that
						CompanionComp.InvestigationDestination.Clear(CompanionComp.InvestigationDestination.GetCurrentInstigator());
					}
				}
			}
		}

		AnimComp.ClearFeature(this);

		UDarkPortalEventHandler::Trigger_OnCompanionInvestigateStopped(Owner);
		UDarkPortalEventHandler::Trigger_OnCompanionInvestigateStopped(CompanionComp.Player);
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
	}

	void ComposeMovement(float DeltaTime)
	{
		if (DeltaTime == 0.0)
			return;

		FVector DestLoc = Destination.Location;
		FVector StartControl = StartLocation + StartTangent;
		FVector EndControl = DestLoc - EndTangent;
		float Length = BezierCurve::GetLength_2CP(StartLocation, StartControl, EndControl, DestLoc);

		float TargetSpeed = Settings.InvestigationSpeed;
		if (Destination.OverrideSpeed > 0.0)
			TargetSpeed = Destination.OverrideSpeed;

		if ((CurrentDistance > Length - 1000.0) && (Destination.Type != EDarkPortalInvestigationType::Flyby))
			Speed.AccelerateTo(TargetSpeed * 0.25, 2.0, DeltaTime); // Slow down at end of curve
		else 
			Speed.AccelerateTo(TargetSpeed, Settings.InvestigationAccelerationDuration, DeltaTime); // Accelerate!

		CurrentDistance += Speed.Value * DeltaTime;

		float Alpha = Math::Min(1.0, CurrentDistance / Length);
		FVector NewLoc = BezierCurve::GetLocation_2CP(StartLocation, StartControl, EndControl, DestLoc, Alpha);
		FVector Delta = NewLoc - Owner.ActorLocation;
		Movement.AddDeltaFromMoveToPositionWithCustomVelocity(NewLoc, Delta / DeltaTime);

		// Rotate to match velocity
		FRotator Rotation = MoveComp.GetRotationTowardsDirection(Delta, 1.0, DeltaTime);
		Movement.SetRotation(Rotation);

		if (CurrentDistance > Length - 10.0)
			bArrived = true;

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			float Interval = 0.01;
			FVector PrevLoc = StartLocation;
			for (float DbgAlpha = Interval; DbgAlpha < 1.0; DbgAlpha += Interval)
			{
				FVector CurveLoc = BezierCurve::GetLocation_2CP(StartLocation, StartControl, EndControl, DestLoc, DbgAlpha);
				Debug::DrawDebugLine(PrevLoc, CurveLoc, FLinearColor::Yellow, 0.0);
				PrevLoc = CurveLoc;
			} 

			Debug::DrawDebugLine(StartLocation, StartControl, FLinearColor::LucBlue, 2);
			Debug::DrawDebugLine(StartControl, EndControl, FLinearColor::LucBlue, 2);
			Debug::DrawDebugLine(EndControl, DestLoc, FLinearColor::LucBlue, 2);
		}
#endif		
	}
}