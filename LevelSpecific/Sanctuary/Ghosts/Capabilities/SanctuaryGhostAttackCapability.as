class USanctuaryGhostAttackCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"SanctuaryGhost");
	default CapabilityTags.Add(n"SanctuaryGhostAttack");

	default TickGroup = EHazeTickGroup::Gameplay;

	ASanctuaryGhost Ghost;

	float AttackDelay = 0.5;
	float DamageInterval = 7.0;
	float DamageTime = 0.0;
	float LiftTime = 0.75;
	bool bAttackStarted = false;

	AHazePlayerCharacter AttackedPlayer;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Ghost = Cast<ASanctuaryGhost>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DeactiveDuration < 0.5)
			return false;

		if (Ghost.TargetPlayer == nullptr)
			return false;

		if (!CanAttackPlayer(Ghost.TargetPlayer))
			return false;

//		if (Ghost.TargetPlayer.IsPlayerDead())
//			return false;

//		if (DeactiveDuration < 0.5)
//			return false;

		if (Ghost.GetDistanceTo(Ghost.TargetPlayer) > Ghost.AttackRange)
			return false;

		if (GhostTownDevToggles::Ghost::DisableAttacks.IsEnabled())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Ghost.TargetPlayer == nullptr)
			return true;

		if (Ghost.TargetPlayer.IsPlayerDead())
			return true;

		if (Ghost.GetDistanceTo(Ghost.TargetPlayer) > Ghost.AttackRange + Ghost.AttackDetachMargin)
			return true;

		if (!CanAttackPlayer(Ghost.TargetPlayer))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bAttackStarted = false;
		DamageTime = 0.0;

		Ghost.BlockCapabilities(n"SanctuaryGhostTarget", this);

/*
		USanctuaryGhostEventHandler::Trigger_OnAttack(Ghost);

		auto AttackResponseComp = USanctuaryGhostAttackResponseComponent::Get(Ghost.TargetPlayer);
		if (AttackResponseComp != nullptr)
			AttackResponseComp.bIsAttacked.Apply(true, this);
*/

		Ghost.bIsAttacking = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Ghost.UnblockCapabilities(n"SanctuaryGhostTarget", this);

		if (bAttackStarted)
		{
			FSanctuaryGhostEventData Data;
			Data.Player = AttackedPlayer;
			USanctuaryGhostEventHandler::Trigger_OnAttackEnd(Ghost, Data);
		}
	
		for (auto Player : Game::Players)
		{
			auto AttackResponseComp = USanctuaryGhostAttackResponseComponent::Get(Ghost.TargetPlayer);
			if (AttackResponseComp != nullptr)
			{
				AttackResponseComp.bIsAttacked.Clear(this);
				AttackResponseComp.Ghosts.Clear(this);
				AttackResponseComp.bIsLifted.Clear(this);
			}
		}

		Ghost.bIsAttacking = false;
		AttackedPlayer = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration < AttackDelay)
			return;

		if (!bAttackStarted)
		{
			bAttackStarted = true;

			AttackedPlayer = Ghost.TargetPlayer;

			FSanctuaryGhostEventData Data;
			Data.Player = Ghost.TargetPlayer;

			USanctuaryGhostEventHandler::Trigger_OnAttack(Ghost, Data);

			auto AttackResponseComp = USanctuaryGhostAttackResponseComponent::Get(Ghost.TargetPlayer);
			if (AttackResponseComp != nullptr)
			{
				AttackResponseComp.bIsAttacked.Apply(true, this);
				AttackResponseComp.Ghosts.Apply(Ghost, this);
//				AttackResponseComp.bIsLifted.Apply(true, this);
			}

		//	Ghost.TargetPlayer.DamagePlayerHealth(0.1);
		}

		if (!Ghost.LightBirdResponseComp.IsIlluminated())
			DamageTime += DeltaTime;

		if (DamageTime >= LiftTime)
		{
			auto AttackResponseComp = USanctuaryGhostAttackResponseComponent::Get(Ghost.TargetPlayer);
			AttackResponseComp.bIsLifted.Apply(true, this);			
		}

		if (DamageTime >= DamageInterval)
		{
			DamageTime = 0.0;
			Ghost.TargetPlayer.KillPlayer(FPlayerDeathDamageParams(), Ghost.DeathEffect);
			USanctuaryGhostEventHandler::Trigger_OnAttackDamage(Ghost);
		}
	
		PrintToScreen("DamageTime: " + DamageTime, 0.0, FLinearColor::Green);
	}

	bool CanAttackPlayer(AHazePlayerCharacter Player) const
	{
		if (Player.IsPlayerDead())
			return false;

		auto AttackResponseComp = USanctuaryGhostAttackResponseComponent::Get(Player);
		if (AttackResponseComp == nullptr)
			return false;

		if (AttackResponseComp.bIsAttacked.Get())
		{
			if (AttackResponseComp.bIsAttacked.CurrentInstigator != this)
				return false;
		}

		auto Trace = Trace::InitChannel(ECollisionChannel::WorldGeometry);
		Trace.IgnoreActor(Ghost);
		Trace.IgnoreActors(Game::Players);
		FVector Start = Ghost.AttackPivot.WorldLocation;
		FVector End = Ghost.TargetPlayer.ActorCenterLocation;
		auto HitResult = Trace.QueryTraceSingle(Start, End);
		if (HitResult.bBlockingHit)
			return false;

		return true;
	}
};