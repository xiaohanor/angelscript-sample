class USanctuaryCompanionAviationPhase1LerpDestinationToQuadCenterCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AviationCapabilityTags::Aviation);
	default TickGroup = EHazeTickGroup::Gameplay;
	USanctuaryCompanionAviationPlayerComponent AviationComp;

	float LerpDuration = 3.0;
	
	FVector OGStart;
	FVector TargetStart;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!HasControl())
			return false;
		if (AviationComp.GetAviationState() != EAviationState::ToAttack)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (AviationComp.GetAviationState() != EAviationState::ToAttack)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FSanctuaryCompanionAviationDestinationData& ToAttackDestination = AviationComp.Destinations[0];
		OGStart = ToAttackDestination.RuntimeSpline.Points[0];
		TargetStart = GetQuadRimCenter() * OGStart.Size2D();
		TargetStart.Z = OGStart.Z;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = Math::Clamp(ActiveDuration / LerpDuration, 0.0, 1.0);
		FSanctuaryCompanionAviationDestinationData& ToAttackDestination = AviationComp.Destinations[0];
		TArray<FVector> Points;

		FVector NewStart = Math::Lerp(OGStart, TargetStart, Alpha);
		FVector NewEnd = ToAttackDestination.RuntimeSpline.Points.Last();
		Points.Add(NewStart);
		Points.Add(NewEnd);
		ToAttackDestination.RuntimeSpline.SetPoints(Points);
		FVector ToDestination = (NewEnd - NewStart).GetSafeNormal();
		ToAttackDestination.RuntimeSpline.SetCustomExitTangentPoint(-ToDestination);
		ToAttackDestination.RuntimeSpline.SetCustomEnterTangentPoint(ToDestination);

		// Debug::DrawDebugLine(TargetStart, NewEnd, ColorDebug::Magenta, 5.0, 0.0, true);
	}

	FVector GetQuadRimCenter()
	{
		float Sign = AviationComp.CurrentQuadrantSide == ESanctuaryArenaSide::Right ? 1.0 : -1.0;
		if (Player.IsMio())
			return FVector::RightVector * Sign;
		return FVector::ForwardVector * Sign;
	}
};