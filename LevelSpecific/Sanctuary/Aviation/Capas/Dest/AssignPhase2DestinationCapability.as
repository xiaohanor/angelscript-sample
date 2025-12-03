struct FSanctuaryCompanionAviationAssignPhase2DestinationParams
{
	FVector PlayerLocation;
}

class USanctuaryCompanionAviationAssignPhase2DestinationCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AviationCapabilityTags::Aviation);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USanctuaryCompanionAviationPlayerComponent AviationComp;
	UInfuseEssencePlayerComponent InfuseEssenceComp;
	ASanctuaryBossArenaManager ArenaManager;

	FVector CachedCenter;
	FTransform SwoopbackTarget;
	FTransform EntryTarget;

	FVector PlayerLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Player);
		InfuseEssenceComp = UInfuseEssencePlayerComponent::Get(Player);
		TListedActors<ASanctuaryBossArenaManager> BossManagers;
		if (BossManagers.Num() == 1)
			ArenaManager = BossManagers[0];
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSanctuaryCompanionAviationAssignPhase2DestinationParams& Params) const
	{
		if (Player.IsPlayerDead())
			return false;

		if(Player.OtherPlayer.IsPlayerDead())
			return false;

		if (!AviationComp.bIsRideReady)
			return false;

		if (AviationComp.HasDestination())
			return false;

		//if (!IsActioning(AviationComp.PromptRide.Action))
			//return false;

		if (ArenaManager != nullptr)
			return false;

		Params.PlayerLocation = Owner.ActorLocation;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSanctuaryCompanionAviationAssignPhase2DestinationParams Params)
	{
		PlayerLocation = Params.PlayerLocation;
		InfuseEssenceComp.ResetOrbs();

		TListedActors<ASanctuaryCompanionAviationLandingPoint> AviationLandingPoints;
		if (AviationLandingPoints.Num() == 0)
			return;

		InfuseEssenceComp.ResetOrbs();
		bool bUseSplineMovement = true;
		if (bUseSplineMovement)
		{
			TArray<FVector> SplinePoints;
			SplinePoints.Add(Owner.ActorLocation);
			SplinePoints.Add(AviationLandingPoints.Single.ActorLocation);
			FSanctuaryCompanionAviationDestinationData Data;
			Data.RuntimeSpline.SetPoints(SplinePoints);
			Data.AviationState = EAviationState::ToAttack;
			AviationComp.AddDestination(Data);
		}
		else
		{
			FSanctuaryCompanionAviationDestinationData Data;
			Data.Actor = AviationLandingPoints.Single;
			AviationComp.AddDestination(Data);
		}

	}


};