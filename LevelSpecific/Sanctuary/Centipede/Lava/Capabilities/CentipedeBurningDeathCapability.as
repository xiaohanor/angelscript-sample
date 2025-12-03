class UCentipedeBurningDeathCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ACentipede Centipede;
	UCentipedeLavaIntoleranceComponent LavaIntoleranceComponent;
	UPlayerCentipedeComponent ZoePlayerCentipedeComponent;
	UPlayerCentipedeComponent MioPlayerCentipedeComponent;

	UHazeActionQueueComponent DeathRespawnQueue;

	UPlayerHealthComponent ZoeHealth;
	UPlayerHealthComponent MioHealth;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LavaIntoleranceComponent = UCentipedeLavaIntoleranceComponent::Get(Owner);
		Centipede = Cast<ACentipede>(Owner);
		DeathRespawnQueue = UHazeActionQueueComponent::Create(Owner);
		ZoeHealth = UPlayerHealthComponent::Get(Game::Zoe);
		MioHealth = UPlayerHealthComponent::Get(Game::Mio);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		bool bDeathVolumeDeath = LavaIntoleranceComponent.bForceDeathMio || LavaIntoleranceComponent.bForceDeathZoe;
		bool bForcedNormalDeath = LavaIntoleranceComponent.Health.Value < KINDA_SMALL_NUMBER && LavaIntoleranceComponent.DeathEvenIfInfiniteHealth();
		if (bDeathVolumeDeath || bForcedNormalDeath)
			return true;
		bool bNormalDeath = LavaIntoleranceComponent.Health.Value < KINDA_SMALL_NUMBER;
		if (!bNormalDeath)
			return false;
		if (IsJesusOrInfHealth())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!AllowingRespawn())
			return false;
		for (AHazePlayerCharacter PlayerCharacter : Game::GetPlayers())
		{
			if (PlayerCharacter.IsPlayerDead() || PlayerCharacter.IsPlayerRespawning())
				return false;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (SanctuaryCentipedeDevToggles::Draw::Burning.IsEnabled())
			Debug::DrawDebugString(Centipede.ActorCenterLocation, "Dead", ColorDebug::Ruby);
	}

	bool IsJesusOrInfHealth() const
	{
		if (MioHealth.GodMode == EGodMode::Jesus)
			return true;
		if (ZoeHealth.GodMode == EGodMode::Jesus)
			return true;
		if (DevTogglesPlayerHealth::ZoeJesusmode.IsEnabled())
			return true;
		if (DevTogglesPlayerHealth::MioJesusmode.IsEnabled())
			return true;
		if (GetCombatModifier(Game::Mio) == ECombatModifier::InfiniteHealth)
			return true;
		if (GetCombatModifier(Game::Zoe) == ECombatModifier::InfiniteHealth)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (ZoePlayerCentipedeComponent == nullptr)
			ZoePlayerCentipedeComponent = UPlayerCentipedeComponent::Get(Game::Zoe);
		if (MioPlayerCentipedeComponent == nullptr)
			MioPlayerCentipedeComponent = UPlayerCentipedeComponent::Get(Game::Mio);
		Kill();
		DeathQueue();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		LavaIntoleranceComponent.bForceDeathMio = false;
		LavaIntoleranceComponent.bForceDeathZoe = false;
		if (AllowingRespawn())
			AllowMovement();
	}

	void DeathQueue()
	{
		if (AllowingRespawn())
		{
			DeathRespawnQueue.Idle(2.0);
			DeathRespawnQueue.Idle(Network::PingOneWaySeconds); // allow remote to teleport into position
			DeathRespawnQueue.Event(this, n"UnhideMeshStartFadeIn");
			DeathRespawnQueue.Duration(1.0, this, n"FadeIn");
			DeathRespawnQueue.Event(this, n"RemoveInvulnerable");
		}
	}

	bool AllowingRespawn() const
	{
		if (ZoePlayerCentipedeComponent != nullptr && !ZoePlayerCentipedeComponent.bAllowRespawn)
			return false;
		if (MioPlayerCentipedeComponent != nullptr && !MioPlayerCentipedeComponent.bAllowRespawn)
			return false;
		return true;
	}

	UFUNCTION()
	private void Kill()
	{
		LavaIntoleranceComponent.bIsRespawning = true;
		LavaIntoleranceComponent.Burns.Reset(32);
		LavaIntoleranceComponent.SetHealth(1.0);
		LavaIntoleranceComponent.Health.SnapRemote();

		Centipede.Mesh.SetHiddenInGame(true, true);

		for (int i = 0; i < Centipede.Segments.Num(); ++i) 
			Niagara::SpawnOneShotNiagaraSystemAtLocation(MioPlayerCentipedeComponent.LavaDeathVFXSystem, Centipede.Segments[i].WorldLocation);

		for (auto PlayerCharacter : Game::GetPlayers())
		{
			if (PlayerCharacter.HasControl())
			{
				if (Centipede.DeathEffect != nullptr)
					PlayerCharacter.KillPlayer(FPlayerDeathDamageParams(), Centipede.DeathEffect);
				else
					PlayerCharacter.KillPlayer();
				PlayerCharacter.BlockCapabilities(CentipedeTags::CentipedeMovement, this);
				PlayerCharacter.PlayForceFeedback(ZoePlayerCentipedeComponent.LavaDeathForceFeedbackEffect, false, true, this);
			}
		}

		Centipede.KillCentipede();
		UCentipedeEventHandler::Trigger_OnBurningDeath(Centipede);
	}

	UFUNCTION()
	private void UnhideMeshStartFadeIn()
	{
		Centipede.Mesh.SetHiddenInGame(false, true);
		Centipede.Mesh.SetScalarParameterValueOnMaterials(n"Dissolve", 1.0);
	}

	UFUNCTION()
	private void FadeIn(float Timer)
	{
		float Alpha = Math::Saturate(1.0 - Timer);
		Centipede.Mesh.SetScalarParameterValueOnMaterials(n"Dissolve", Alpha);
	}

	UFUNCTION()
	private void AllowMovement()
	{
		for (auto PlayerCharacter : Game::GetPlayers())
		{
			if (PlayerCharacter.HasControl())
				PlayerCharacter.UnblockCapabilities(CentipedeTags::CentipedeMovement, this);
		}
	}

	UFUNCTION()
	private void RemoveInvulnerable()
	{
		LavaIntoleranceComponent.bIsRespawning = false;
		LavaIntoleranceComponent.bForceDeathMio = false;
		LavaIntoleranceComponent.bForceDeathZoe = false;
		LavaIntoleranceComponent.SetHealth(1.0);
	}
}