struct FDentistBossToolCupRestrainPlayerActivationParams
{
	AHazePlayerCharacter RestrainedPlayer;
}

class UDentistBossToolCupRestrainPlayerCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	ADentistBossToolCup Cup;
	ADentistBoss Dentist;
	ADentistBossCupManager CupManager;
	UDentistBossTargetComponent TargetComp;

	UDentistBossSettings Settings;

	AHazePlayerCharacter RestrainedPlayer;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Cup = Cast<ADentistBossToolCup>(Owner);

		Dentist = TListedActors<ADentistBoss>().GetSingle();
		TargetComp = UDentistBossTargetComponent::Get(Dentist);

		CupManager = Dentist.CupManager;
		Settings = UDentistBossSettings::GetSettings(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FDentistBossToolCupRestrainPlayerActivationParams& Params) const
	{
		if(!Cup.bActive)
			return false;

		if(!Cup.RestrainedPlayer.IsSet())
			return false;

		Params.RestrainedPlayer = Cup.RestrainedPlayer.Value;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Cup.bActive)
			return true;

		if(!Cup.RestrainedPlayer.IsSet())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FDentistBossToolCupRestrainPlayerActivationParams Params)
	{
		RestrainedPlayer = Params.RestrainedPlayer;
		RestrainedPlayer.BlockCapabilities(CapabilityTags::Movement, this);
		RestrainedPlayer.BlockCapabilities(CapabilityTags::Collision, this);
		RestrainedPlayer.ActivateCamera(CupManager.PlayerCaughtCamera, 5.5, this);
		RestrainedPlayer.AttachToActor(Cup, AttachmentRule = EAttachmentRule::SnapToTarget);
		RestrainedPlayer.BlockCapabilities(CapabilityTags::Visibility, this);
		RestrainedPlayer.OtherPlayer.BlockCapabilities(CapabilityTags::FindOtherPlayer, this);
		RestrainedPlayer.BlockCapabilities(CapabilityTags::FindOtherPlayer, this);
		RestrainedPlayer.OtherPlayer.BlockCapabilities(CapabilityTags::OtherPlayerIndicator, this);
		Dentist.HasSwatAmnesty[RestrainedPlayer] = true;
		TargetComp.CupRestrainedPlayer = RestrainedPlayer;

		CupManager.PlayerInCup = RestrainedPlayer;

		FDentistBossEffectHandlerOnPlayerCaughtByCupParams EffectParams;
		EffectParams.PlayerCaughtByCup = RestrainedPlayer;

		UDentistBossEffectHandler::Trigger_OnPlayerCaughtInCup(Dentist, EffectParams);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(!Cup.FlattenedPlayer.IsSet()
		|| RestrainedPlayer != Cup.FlattenedPlayer.Value)
		{
			RestrainedPlayer.ActorLocation = Cup.ActorLocation + FVector::DownVector * (DentistBossMeasurements::CupHeight);
			RestrainedPlayer.ActorRotation = FRotator::MakeFromXZ(Dentist.SkelMesh.ForwardVector, FVector::UpVector);
			auto ToothComp = UDentistToothPlayerComponent::Get(RestrainedPlayer);
			ToothComp.SetMeshWorldRotation(RestrainedPlayer.ActorQuat, this);
			FVector MovementImpulse = 
				Dentist.SkelMesh.ForwardVector * 750.0
				+ FVector::UpVector * 1250.0;
			RestrainedPlayer.AddMovementImpulse(MovementImpulse);
		}
		RestrainedPlayer.UnblockCapabilities(CapabilityTags::Movement, this);
		RestrainedPlayer.UnblockCapabilities(CapabilityTags::Collision, this);
		RestrainedPlayer.DeactivateCamera(CupManager.PlayerCaughtCamera, 1.0);
		RestrainedPlayer.DetachFromActor(EDetachmentRule::KeepWorld);
		RestrainedPlayer.UnblockCapabilities(CapabilityTags::Visibility, this);
		RestrainedPlayer.OtherPlayer.UnblockCapabilities(CapabilityTags::FindOtherPlayer, this);
		RestrainedPlayer.UnblockCapabilities(CapabilityTags::FindOtherPlayer, this);
		RestrainedPlayer.OtherPlayer.UnblockCapabilities(CapabilityTags::OtherPlayerIndicator, this);
		Dentist.HasSwatAmnesty[RestrainedPlayer] = false;
	}
}