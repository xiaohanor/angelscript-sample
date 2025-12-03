class USanctuaryCompanionAviationToAttackDestinationCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AviationCapabilityTags::Aviation);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USanctuaryCompanionAviationPlayerComponent AviationComp;
	ASanctuaryBossArenaManager ArenaManager;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Player);
		TListedActors<ASanctuaryBossArenaManager> BossManagers;
		if (BossManagers.Num() == 1)
			ArenaManager = BossManagers[0];
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!AviationComp.HasDestination())
			return false;

		if (!AviationComp.GetIsAviationActive())
			return false;

		if (!IsInStateHandledByThisCapability())
			return false;

		if (!AviationComp.HasControl())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!AviationComp.GetIsAviationActive())
			return true;

		if (!IsInStateHandledByThisCapability())
			return true;

		// Can happen in tutorial if in network
		if (!AviationComp.HasDestination()) 
			return true;

		return false;
	}

	bool IsInStateHandledByThisCapability() const
	{
		if (AviationComp.AviationState == EAviationState::ToAttack)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AviationComp.AviationAllowedInputAlpha = 0.0;
		AviationComp.AviationUseSplineParallelAlpha = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!HasControl())
			return;
		
		const FSanctuaryCompanionAviationDestinationData& DestinationData = AviationComp.GetNextDestination();
		AviationComp.AviationAllowedInputAlpha = 0.0;
		if (DestinationData.HasRuntimeSpline())
		{
			
			FVector SplinePos = DestinationData.RuntimeSpline.GetClosestLocationToLocation(Player.ActorLocation);
			FVector ToTarget = SplinePos - Owner.ActorLocation;
			
			float OutsideFalloff = Math::Clamp(ToTarget.Size() - AviationComp.Settings.ToAttackAllowedDistanceFromSpline, 0.0, AviationComp.Settings.ToAttackFalloffDistanceFromSpline);
			float OutsideAllowedFraction = Math::Clamp(OutsideFalloff / AviationComp.Settings.ToAttackFalloffDistanceFromSpline, 0.0, 1.0);
			AviationComp.AviationUseSplineParallelAlpha = Math::EaseInOut(1.0, 0.1, OutsideAllowedFraction, 2.0);
			AviationComp.AviationAllowedInputAlpha = Math::EaseInOut(AviationComp.Settings.ToAttackMaxInputWeight, 0.0, OutsideAllowedFraction, 2.0);
			// PrintToScreen("ToTarget: " + ToTarget.Size());
			// PrintToScreen("Outside: " + OutsideFalloff);
			// PrintToScreen("Fraction: " + OutsideAllowedFraction);
			// PrintToScreen("Allowed input: " + AviationComp.AviationAllowedInputAlpha);
		}
	}
};