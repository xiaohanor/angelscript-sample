struct FLightBirdInvestigateParams
{
	USceneComponent TargetComp;
}

class USanctuaryLightBirdCompanionInvestigateCapability : UHazeCapability
{
	default CapabilityTags.Add(BasicAITags::Behaviour);
	default CapabilityTags.Add(LightBird::Tags::LightBird);
	default CapabilityTags.Add(LightBird::Tags::LightBirdInvestigate);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 10; // Before all others

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USanctuaryLightBirdCompanionComponent CompanionComp;
	UBasicAICharacterMovementComponent MoveComp;
	USanctuaryLightBirdCompanionSettings Settings;
	UTeleportingMovementData Movement;
	UBasicAIAnimationComponent AnimComp; 

	FVector StartLocation; 
	FVector StartTangent;
	FVector EndTangent; 

	FHazeAcceleratedFloat Speed;
	float CurrentDistance;
	FLightBirdInvestigationDestination Destination;	
	bool bArrived = false;

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
	bool ShouldActivate(FLightBirdInvestigateParams & OutParams) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		if (!ShouldInvestigate(CompanionComp.InvestigationDestination.Get()))
			return false;
		if (CompanionComp.State == ELightBirdCompanionState::InvestigatingAttached)
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
		if (CompanionComp.State != ELightBirdCompanionState::Investigating)
			return true;
		if (CompanionComp.InvestigationDestination.Get() != Destination)
			return true; // Found a new shiny thing or lost the current one
		if (!ShouldInvestigate(Destination))
			return true;
		return false;
	}

	bool ShouldInvestigate(FLightBirdInvestigationDestination Dest) const
	{
		if (!Dest.IsValid())
			return false;
		if (Dest.bOverridePlayerControl)
			return true;		
		if (CompanionComp.UserComp.State != ELightBirdState::Hover)
			return false;
		if (!CompanionComp.IsFreeFlying() && (CompanionComp.State != ELightBirdCompanionState::Investigating))
			return false;	
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FLightBirdInvestigateParams Params)
	{
		CompanionComp.State = ELightBirdCompanionState::Investigating;
		bArrived = false;

		// We must detach before commencing move
		CompanionComp.Detach();

		Destination.TargetComp = Params.TargetComp; // Set component on remote
		Destination = CompanionComp.InvestigationDestination.Get();

		if (!Destination.IsValid())
		{
			// Attach target has become invalid after end of launch but before this was activated. 
			// Revert to follow state, then deactivate
			CompanionComp.State = ELightBirdCompanionState::Follow;
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

		AnimComp.RequestFeature(LightBirdCompanionAnimTags::Investigate, EBasicBehaviourPriority::Medium, this);		

		ULightBirdEventHandler::Trigger_InvestigateStarted(Owner);
		ULightBirdEventHandler::Trigger_InvestigateStarted(CompanionComp.Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (CompanionComp.State == ELightBirdCompanionState::Investigating)
		{
			// Should we land at target or was this just a fly-by?
			if (Destination.Type == ELightBirdInvestigationType::Attach)
			{
				CompanionComp.State = ELightBirdCompanionState::InvestigatingAttached;
			}
			else
			{
				CompanionComp.State = ELightBirdCompanionState::Follow;

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

		CompanionComp.Illuminators.RemoveSingleSwap(this);
		CompanionComp.ForceIlluminators.RemoveSingleSwap(this);

		ULightBirdEventHandler::Trigger_InvestigateStopped(Owner);
		ULightBirdEventHandler::Trigger_InvestigateStopped(CompanionComp.Player);
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

		if (HasControl() && Owner.ActorLocation.IsWithinDist(Destination.Location, Settings.InvestigationIlluminationRange) && !CompanionComp.Illuminators.Contains(this))
			CrumbStartIlluminating(Destination.bAutoIlluminate);
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

		if ((CurrentDistance > Length - 1000.0) && (Destination.Type != ELightBirdInvestigationType::Flyby))
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

	UFUNCTION(CrumbFunction)
	void CrumbStartIlluminating(bool bForceIlluminate)
	{
		CompanionComp.Illuminators.Add(this);
		if (bForceIlluminate)
			CompanionComp.ForceIlluminators.Add(this);
	}
};