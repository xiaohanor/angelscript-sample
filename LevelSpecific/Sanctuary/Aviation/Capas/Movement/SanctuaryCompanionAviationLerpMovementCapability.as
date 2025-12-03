class USanctuaryCompanionAviationLerpMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AviationCapabilityTags::Aviation);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default DebugCategory = AviationCapabilityTags::Aviation;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 80;

	USanctuaryCompanionAviationPlayerComponent AviationComp;
	UPlayerMovementComponent MoveComp;
    USimpleMovementData Movement;

	float OriginalDistance;
	bool bDebug = false;

	float DurationThing = 0.5;

	FVector ControlOGLocation;
	FSanctuaryCompanionAviationDestinationSplineData DestinationSplineData;

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

		if (!IsInHandledState())
			return false;

		const FSanctuaryCompanionAviationDestinationData& DestinationData = AviationComp.GetNextDestination();
		if (!DestinationData.bLerp)
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

		const FSanctuaryCompanionAviationDestinationData& DestinationData = AviationComp.GetNextDestination();
		if (!DestinationData.bLerp)
			return true;

		if (!IsInHandledState())
			return true;

		return false;
	}

	bool IsInHandledState() const
	{
		if (AviationComp.GetAviationState() == EAviationState::SwoopingBack)
			return true;

		if (AviationComp.GetAviationState() == EAviationState::Entry)
			return true;

		if (AviationComp.GetAviationState() == EAviationState::SwoopInAttack)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ControlOGLocation = Player.ActorLocation;
		Owner.BlockCapabilities(BlockedWhileIn::AirMotion, this);
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Apply(false, this);
        if (!HasControl())
            return;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(BlockedWhileIn::AirMotion, this);
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Clear(this);
		if (!HasControl())
            return;
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
				const FSanctuaryCompanionAviationDestinationData& DestinationData = AviationComp.GetNextDestination();
				FVector ToTarget;
				AviationComp.ResetEndOfMovementSpline();
				FVector SplineDirection = FVector::ZeroVector;
				if (DestinationData.HasRuntimeSpline())
				{
					if (bDebug)
						DestinationData.RuntimeSpline.DrawDebugSpline();

					float LerpAlpha = Math::Clamp(ActiveDuration / DurationThing, 0.0, 1.0);
					if (LerpAlpha >= 1.0) 
						AviationComp.SetEndOfMovementSpline();
					
					DestinationData.GetSplineData(Player.ActorLocation, DestinationData.RuntimeSpline.Length, DestinationSplineData);
					ToTarget = Math::Lerp(ControlOGLocation, DestinationSplineData.NextSplineLocation, LerpAlpha);
					if (bDebug)
						Debug::DrawDebugLine(Player.ActorLocation, DestinationSplineData.NextSplineLocation, FLinearColor::LucBlue, 10.0, 0.0, true);
				}

				ToTarget = ToTarget - Player.ActorLocation;
                Movement.AddDelta(ToTarget);
                // Movement.AddDelta(FVector());
				// Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + NewForwardVelocity, FLinearColor::LucBlue, 5.0, 0.0, true);
				if (ToTarget.Size() > KINDA_SMALL_NUMBER)
					Movement.SetRotation(FRotator::MakeFromXZ(ToTarget.GetSafeNormal(), FVector::UpVector));
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
			MoveComp.ApplyMove(Movement);
		}
	}
}

