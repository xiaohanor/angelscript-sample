class USummitKnightSingleSlashBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	USummitKnightSettings Settings;
	
	FBasicAIAnimationActionDurations Durations;

	USummitKnightComponent KnightComp;
	USummitKnightAnimationComponent KnightAnimComp;
	USummitKnightSceptreComponent Sceptre;
	USummitKnightBladeComponent Blade;
	USummitKnightGenericAttackShockwaveLauncher Launcher;
	ASummitKnightGenericAttackShockwave Shockwave;	
	AHazePlayerCharacter TargetPlayer;
	bool bTriggeredShockwave;

	bool bHasStartedSwing;
	bool bHasTriggeredBladeImpact;

	float ShockwaveSpeedFactor = 1.0;
	float AnimTimeScale = 1.0;

	TPerPlayer<bool> DirectHits;
	TPerPlayer<bool> NearHits;
	bool bShockwaveExpired;

	USummitKnightSingleSlashBehaviour(float AnimPlayRate, float ProjectileSpeedFactor)
	{
		AnimTimeScale = AnimPlayRate;
		ShockwaveSpeedFactor = ProjectileSpeedFactor;
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USummitKnightSettings::GetSettings(Owner);
		KnightAnimComp = USummitKnightAnimationComponent::GetOrCreate(Owner);
		KnightComp = USummitKnightComponent::Get(Owner);

		Sceptre = USummitKnightSceptreComponent::Get(Owner);
		TArray<USummitKnightBladeComponent> Blades;
		Owner.GetComponentsByClass(Blades);
		Blade = Blades[0];

		TArray<USummitKnightGenericAttackShockwaveLauncher> Launchers;
		Blade.GetChildrenComponentsByClass(USummitKnightGenericAttackShockwaveLauncher, true, Launchers);
		Launcher = Launchers[0];
		Launcher.PrepareProjectiles(4);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Durations.GetTotal())	
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		Durations.Telegraph = Settings.SingleSlashTelegraphDuration;
		Durations.Anticipation = Settings.SingleSlashAnticipationDuration;
		Durations.Action = Settings.SingleSlashActionDuration;
		Durations.Recovery = Settings.SingleSlashRecoverDuration;
		KnightAnimComp.FinalizeDurations(SummitKnightFeatureTags::SingleSlash, NAME_None, Durations);
		Durations.ScaleAll(AnimTimeScale);
		AnimComp.RequestAction(SummitKnightFeatureTags::SingleSlash, NAME_None, EBasicBehaviourPriority::Medium, this, Durations);

		Blade.Equip();

		TargetPlayer = Cast<AHazePlayerCharacter>(TargetComp.Target);
		if (TargetPlayer == nullptr)
			TargetPlayer = Game::Mio;
		if (!TargetComp.IsValidTarget(TargetPlayer) && TargetComp.IsValidTarget(TargetPlayer.OtherPlayer))
			TargetPlayer = TargetPlayer.OtherPlayer;

		USummitKnightSettings::SetRotationDuration(Owner, Settings.SingleSlashTurnDuration, this);

		bTriggeredShockwave = false;
		bHasStartedSwing = false;
		bHasTriggeredBladeImpact = false;
		
		for (AHazePlayerCharacter Player : Game::Players)
		{
			NearHits[Player] = false;
			DirectHits[Player] = false;
		}
		bShockwaveExpired = false;

		USummitKnightEventHandler::Trigger_OnSingleSlashTelegraph(Owner, FSummitKnightPlayerParams(TargetPlayer));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		TargetComp.SetTarget(TargetPlayer.OtherPlayer);
		Owner.ClearSettingsByInstigator(this);
		Super::OnDeactivated();

		if (bTriggeredShockwave && !bShockwaveExpired && !IsAnyHits() && (Shockwave != nullptr) && !Shockwave.HasHitAnyTargets())
			USummitKnightEventHandler::Trigger_OnSingleSlashMiss(Owner, FSummitKnightPlayerParams(TargetPlayer));

		if (HasControl() && !bTriggeredShockwave)
			CrumbAborted();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration < Durations.Telegraph)
		{
			FVector TargetLoc = GetTargetLocation();
			DestinationComp.RotateTowards(TargetLoc);
		}
		if(!bHasStartedSwing && ActiveDuration > (Durations.Telegraph - 0.2))
		{
			bHasStartedSwing = true;
			USummitKnightEventHandler::Trigger_OnSingleSlashImpact(Owner);
		}

		if (!bTriggeredShockwave && Durations.IsInActionRange(ActiveDuration) && HasControl())
			CrumbLaunchShockwave(Blade.TipLocation, (Blade.TipLocation - Blade.HiltLocation).GetSafeNormal2D());

		if (!bHasTriggeredBladeImpact && Durations.IsInActionRange(ActiveDuration))
		{
			bHasTriggeredBladeImpact = true;
			FVector BladeDir = (Blade.TipLocation - Blade.HiltLocation).GetSafeNormal2D();
			FVector BaseLoc = KnightComp.Arena.GetAtArenaHeight(Blade.HiltLocation);
			FVector TipLoc = KnightComp.Arena.GetAtArenaHeight(BaseLoc + BladeDir * Blade.BladeLength); // Ensure we get full length along arena even if animnotify is slightly misplaced
			float OuterRadius = Settings.GenericAttackBladeImpactKnockbackWidth;
			float KillRadius = Settings.GenericAttackBladeImpactKillWidth;			
			USummitKnightEventHandler::Trigger_OnSingleSlashImpactGround(Owner);

			for (AHazePlayerCharacter Player : Game::Players)
			{
				if (!Player.HasControl())
					continue;
				if (Player.ActorLocation.Z > Owner.ActorLocation.Z + 1000.0)
					continue;
				FVector PlayerArenaLoc = KnightComp.Arena.GetAtArenaHeight(Player.ActorLocation);
				if (!PlayerArenaLoc.IsInsideTeardrop2D(BaseLoc, TipLoc, OuterRadius, OuterRadius))
					continue;
				if (Player.IsPlayerDead())
					continue;
				CrumbHitPlayer(Player, PlayerArenaLoc.IsInsideTeardrop2D(BaseLoc, TipLoc, KillRadius, KillRadius));
			}
			KnightComp.SmashObstaclesInTeardrop(BaseLoc, TipLoc, OuterRadius, OuterRadius);
		}

		if (!bShockwaveExpired && bTriggeredShockwave && Shockwave.ProjectileComp.bIsExpired && (Shockwave != nullptr))
		{
			bShockwaveExpired = true;
			if (!IsAnyHits() && !Shockwave.HasHitAnyTargets())
				USummitKnightEventHandler::Trigger_OnSingleSlashMiss(Owner, FSummitKnightPlayerParams(TargetPlayer));
		}
	}

	FVector GetTargetLocation()
	{
		return TargetPlayer.ActorLocation + Owner.ActorRightVector * Owner.ActorLocation.Dist2D(TargetPlayer.ActorLocation) * 0.05;
	}

	UFUNCTION(CrumbFunction)
	void CrumbHitPlayer(AHazePlayerCharacter Player, bool bDirectHit)
	{
		FVector PlayerArenaLoc = KnightComp.Arena.GetAtArenaHeight(Player.ActorLocation);
		FVector BaseLoc = KnightComp.Arena.GetAtArenaHeight(Blade.HiltLocation);
		FVector BladeDir = (Blade.TipLocation - Blade.HiltLocation).GetSafeNormal2D();
		FVector TipLoc = KnightComp.Arena.GetAtArenaHeight(BaseLoc + BladeDir * Blade.BladeLength); // Ensure we get full length along arena even if animnotify is slightly misplaced
		FVector LineLoc;
		float Dummy;
		Math::ProjectPositionOnLineSegment(BaseLoc, TipLoc, PlayerArenaLoc, LineLoc, Dummy);
		FVector StumbleDir = (PlayerArenaLoc - LineLoc).GetNormalized2DWithFallback(-Player.ActorForwardVector);
		KnightComp.StumbleDragon(Player, StumbleDir * Settings.GenericAttackShockwaveStumbleDistance, 0.0, 0.5, 200.0);				

		if (bDirectHit)
		{
			// Splat!
			DirectHits[Player] = true;
			Player.DealTypedDamage(Owner, 1.0, EDamageEffectType::ObjectLarge, EDeathEffectType::ObjectLarge, false);
			KnightComp.bDeathCouldHaveBeenDashAvoided[Player] = true;

			USummitKnightEventHandler::Trigger_OnSingleSlashDirectHit(Owner, FSummitKnightPlayerParams(Player));
			if (DirectHits[Player.OtherPlayer])
				USummitKnightEventHandler::Trigger_OnSingleSlashDirectHitBoth(Owner);
		}
		else
		{
			NearHits[Player] = true;
			USummitKnightEventHandler::Trigger_OnSingleSlashNearHit(Owner, FSummitKnightPlayerParams(Player));
		}
	}

	bool IsAnyHits() const
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (DirectHits[Player] || NearHits[Player])
				return true;
		}
		return false;
	}

	UFUNCTION(CrumbFunction)
	void CrumbAborted()
	{
		USummitKnightEventHandler::Trigger_OnSingleSlashAborted(Owner);
	}

	UFUNCTION(CrumbFunction)
	void CrumbLaunchShockwave(FVector Location, FVector Direction)
	{
		bTriggeredShockwave = true;
		UBasicAIProjectileComponent Projectile = Launcher.Launch(Direction * Settings.GenericAttackShockwaveMoveSpeed * ShockwaveSpeedFactor);
		Shockwave = Cast<ASummitKnightGenericAttackShockwave>(Projectile.Owner);
		Shockwave.LaunchLocal(Location, Owner);
	}
}

