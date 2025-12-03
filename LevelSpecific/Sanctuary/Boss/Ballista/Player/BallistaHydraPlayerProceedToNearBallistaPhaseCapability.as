class UBallistaHydraPlayerProceedToNearBallistaPhaseCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::AfterGameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::ImmediateNetFunction;

	UMedallionPlayerReferencesComponent MedRefs;
	UBallistaHydraActorReferencesComponent BallistaRefs;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MedRefs = UMedallionPlayerReferencesComponent::GetOrCreate(Player);
		BallistaRefs = UBallistaHydraActorReferencesComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DeactiveDuration < 1.0) // if using dev progress point, allow things to settle first
			return false;

		if (Network::IsGameNetworked() && !Network::HasWorldControl())
			return false;
		if (!Network::IsGameNetworked() && Player.IsZoe())
			return false;
		if (MedRefs.Refs == nullptr)
			return false;
		if (BallistaRefs.Refs == nullptr)
			return false;

		bool bBothNearBallista = IsNearBallista(Player) && IsNearBallista(Player.OtherPlayer);
		if (!bBothNearBallista)
			return false;

		return true;
	}

	bool IsNearBallista(AHazePlayerCharacter NearPlayer) const
	{
		if (NearPlayer.IsPlayerDead() && !NearPlayer.OtherPlayer.IsPlayerDead())
			return true;
		if (MedRefs.Refs.HydraAttackManager.Phase == EMedallionPhase::Ballista1 && BallistaRefs.Refs.FirstBallista.ActorLocation.Dist2D(NearPlayer.ActorLocation) < MedallionConstants::Ballista::TriggerNearBallistaPhaseDistanceToPlayer)
			return true;
		if (MedRefs.Refs.HydraAttackManager.Phase == EMedallionPhase::Ballista2 && BallistaRefs.Refs.SecondBallista.ActorLocation.Dist2D(NearPlayer.ActorLocation) < MedallionConstants::Ballista::TriggerNearBallistaPhaseDistanceToPlayer)
			return true;
		if (MedRefs.Refs.HydraAttackManager.Phase == EMedallionPhase::Ballista3 && BallistaRefs.Refs.ThirdBallista.ActorLocation.Dist2D(NearPlayer.ActorLocation) < MedallionConstants::Ballista::TriggerNearBallistaPhaseDistanceToPlayer)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (MedRefs.Refs.HydraAttackManager.Phase == EMedallionPhase::Ballista1)
			MedRefs.Refs.HydraAttackManager.SetPhase(EMedallionPhase::BallistaNearBallista1);
		if (MedRefs.Refs.HydraAttackManager.Phase == EMedallionPhase::Ballista2)
			MedRefs.Refs.HydraAttackManager.SetPhase(EMedallionPhase::BallistaNearBallista2);
		if (MedRefs.Refs.HydraAttackManager.Phase == EMedallionPhase::Ballista3)
			MedRefs.Refs.HydraAttackManager.SetPhase(EMedallionPhase::BallistaNearBallista3);
	}
};