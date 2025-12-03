class USanctuaryCompanionAviationEntryMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AviationCapabilityTags::Aviation);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default DebugCategory = AviationCapabilityTags::Aviation;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 90;

	USanctuaryCompanionAviationPlayerComponent AviationComp;
	UPlayerMovementComponent MoveComp;
    USimpleMovementData Movement;
	FSanctuaryCompanionAviationDestinationSplineData DestinationSplineData;

	float EntrySpeedAlpha = 0.0;
	float OriginalDistance;

	bool bDebug = false;

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

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.BlockCapabilities(BlockedWhileIn::AirMotion, this);
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Apply(false, this);
        if (!HasControl())
            return;
		EntrySpeedAlpha = 0.0;
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

					DestinationData.GetSplineData(Player.ActorLocation, GetCurrentSpeed() * DeltaTime, DestinationSplineData);//SplinePos, SplineDirection, AviationComp.bControlIsAtEndOfMovementSpline, TraversedPercent);
					ToTarget = DestinationSplineData.NextSplineLocation - Owner.ActorLocation;
					if (DestinationSplineData.bIsAtEnd || AviationComp.bControlIsAtEndOfMovementSpline)
						AviationComp.SetEndOfMovementSpline();

					if (bDebug)
						Debug::DrawDebugLine(Player.ActorLocation, DestinationSplineData.NextSplineLocation, FLinearColor::LucBlue, 10.0, 0.0, true);

					if (AviationComp.AviationState == EAviationState::Entry)
					{
						EntrySpeedAlpha = DestinationSplineData.TraversedPercent;
						// PrintToScreen("% " + EntrySpeedAlpha);
					}
				}
                Movement.AddDelta(ToTarget);

				// Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + NewForwardVelocity, FLinearColor::LucBlue, 5.0, 0.0, true);
				Movement.SetRotation(FRotator::MakeFromXZ(ToTarget.GetSafeNormal(), FVector::UpVector));
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
			MoveComp.ApplyMove(Movement);
		}
	}

	// -------------------

	private float GetCurrentSpeed()
	{
		if (AviationComp.AviationState == EAviationState::SwoopingBack)
			return AviationComp.Settings.SwoopbackSpeed;
		if (AviationComp.AviationState == EAviationState::Entry)
			return Math::Lerp(AviationComp.Settings.EntrySpeed, AviationComp.Settings.SidewaysForwardSpeed, EntrySpeedAlpha);
		return AviationComp.Settings.ExitSpeed;
	}
}

