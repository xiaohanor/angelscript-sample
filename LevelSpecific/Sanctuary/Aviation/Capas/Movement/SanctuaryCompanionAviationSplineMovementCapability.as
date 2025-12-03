class USanctuaryCompanionAviationSplineMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AviationCapabilityTags::Aviation);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default DebugCategory = AviationCapabilityTags::Aviation;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 100;

	USanctuaryCompanionAviationPlayerComponent AviationComp;
	UPlayerMovementComponent MoveComp;
    USimpleMovementData Movement;

	FVector FutureSplineLocation;
	FQuat FutureSplineQuat;
	float SplineDistance = 0.0;

	FHazeAcceleratedVector AccTargetLocation;
	FHazeAcceleratedFloat AccSpeed;
	FHazeAcceleratedRotator AccRotator;

	bool bDebug = false;
	bool bTutorial = false;
	float EntrySpeedAlpha = 0.0;

	FVector EntryLocation;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Owner);
		AviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Owner);
		Movement = MoveComp.SetupSimpleMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!AviationComp.GetIsAviationActive())
			return false;

		if (!AviationComp.HasDestination())
			return false;

		if (IsInUnhandledState())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (!AviationComp.GetIsAviationActive())
			return true;

		if (!AviationComp.HasDestination())
			return true;

		if (IsInUnhandledState())
			return true;

		return false;
	}

	bool IsInUnhandledState() const
	{
		if (AviationComp.GetAviationState() == EAviationState::ToAttack)
			return true;
		if (AviationComp.GetAviationState() == EAviationState::InitAttack)
			return true;
		if (AviationComp.GetAviationState() == EAviationState::Attacking)
			return true;
		if (AviationComp.GetAviationState() == EAviationState::TryExitAttack)
			return true;
		if (AviationComp.GetAviationState() == EAviationState::AttackingSuccessCircling)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		EntryLocation = Player.ActorLocation;

		SplineDistance = 0.0;
		Owner.BlockCapabilities(BlockedWhileIn::AirMotion, this);
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Apply(false, this);
        
		if (!HasControl())
            return;

		AccSpeed.SnapTo(MoveComp.Velocity.Size());
		AccTargetLocation.SnapTo(Owner.ActorLocation);
		AccTargetLocation.Velocity = MoveComp.Velocity;
		AviationComp.ResetEndOfMovementSpline();
		AccRotator.SnapTo(Player.ActorRotation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(BlockedWhileIn::AirMotion, this);
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Clear(this);
		if (HasControl())
			AviationComp.ResetEndOfMovementSpline();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				bDebug = AviationDevToggles::DrawPath.IsEnabled();
				AccSpeed.AccelerateTo(GetCurrentSpeed(), 0.2, DeltaTime);
				SplineDistance += AccSpeed.Value * DeltaTime;
				float SoftStartAlpha = Math::Lerp(1.0, 0.01, Math::Clamp(ActiveDuration, 0.0, 1.0));

				UpdateDataFromSpline(DeltaTime);
				
				AccTargetLocation.AccelerateTo(FutureSplineLocation, SoftStartAlpha, DeltaTime);
				Movement.AddDeltaFromMoveToPositionWithCustomVelocity(AccTargetLocation.Value, AccTargetLocation.Velocity);
				
				FRotator TargetRot = FRotator::MakeFromXZ(FutureSplineQuat.ForwardVector, FVector::UpVector);

				bool bShouldSnap = ActiveDuration >= 1.0;
				if (bShouldSnap)
					AccRotator.SnapTo(TargetRot);
				else
					AccRotator.AccelerateTo(TargetRot, SoftStartAlpha, DeltaTime);
				Movement.SetRotation(AccRotator.Value);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
			MoveComp.ApplyMove(Movement);
		}
	}

	// -------------------

	private void UpdateDataFromSpline(float DeltaTime)
	{
		const FSanctuaryCompanionAviationDestinationData& DestinationData = AviationComp.GetNextDestination();
		if (DestinationData.HasRuntimeSpline())
		{
			if (bDebug)
				DestinationData.RuntimeSpline.DrawDebugSpline();

			if (SplineDistance >= DestinationData.RuntimeSpline.Length)
			{
				SplineDistance = DestinationData.RuntimeSpline.Length;
				AviationComp.SetEndOfMovementSpline();
			}

			if (DestinationData.RuntimeSpline.Points.Num() == 2)
			{
				FVector StartLocation = DestinationData.RuntimeSpline.Points[0];
				FVector EndLocation = DestinationData.RuntimeSpline.Points[1];
				FVector Direction = (EndLocation - StartLocation).GetSafeNormal();
				FutureSplineQuat = FRotator::MakeFromXZ(Direction, FVector::UpVector).Quaternion();
				FutureSplineLocation = StartLocation + Direction * SplineDistance;
			}
			else
				DestinationData.RuntimeSpline.GetLocationAndQuatAtDistance(SplineDistance, FutureSplineLocation, FutureSplineQuat);
			
			if (bDebug)
			{
				Debug::DrawDebugSphere(FutureSplineLocation);
				Debug::DrawDebugCoordinateSystem(FutureSplineLocation, FutureSplineQuat.Rotator(), 300.0);
			}
		}
		else
		{
			FVector TotalDelta = DestinationData.GetLocation() - EntryLocation;
			if (SplineDistance >= TotalDelta.Size())
			{
				SplineDistance = TotalDelta.Size();
				AviationComp.SetEndOfMovementSpline();
			}

			FVector Direction = TotalDelta.GetSafeNormal();
			FutureSplineQuat = FRotator::MakeFromXZ(Direction, FVector::UpVector).Quaternion();
			FutureSplineLocation = EntryLocation + Direction * SplineDistance;	
		}
	}

	private float GetCurrentSpeed()
	{
		if (AviationComp.AviationState == EAviationState::SwoopingBack)
			return AviationComp.Settings.SwoopbackSpeed;
		if (AviationComp.AviationState == EAviationState::Entry)
			return Math::Lerp(AviationComp.Settings.EntrySpeed, AviationComp.Settings.SidewaysForwardSpeed, EntrySpeedAlpha);
		if (AviationComp.AviationState == EAviationState::InitAttack)
			return AviationComp.Settings.InitiateAttackSpeed;
		return AviationComp.Settings.ExitSpeed;
	}
}