class USummitKnightDualSlashBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	USummitKnightSettings Settings;
	
	USummitKnightComponent KnightComp;
	USummitKnightAnimationComponent KnightAnimComp;
	USummitKnightSceptreComponent Sceptre;
	USummitKnightBladeComponent Blade;
	USummitKnightGenericAttackShockwaveLauncher Launcher;
	AHazePlayerCharacter TargetPlayer;
	int NumTriggeredImpacts;
	TArray<FHazeAnimNotifyStateGatherInfo> ActionInfo; 
	TArray<FHazeAnimNotifyStateGatherInfo> TelegraphInfo; 
	float FullDuration;
	bool bHasStartedSecondTelegraph = false;
	bool bHasStartedFirstSwing = false;
	bool bHasStartedSecondSwing = false;

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
		Launcher.PrepareProjectiles(2);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > FullDuration)	
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		FullDuration = 0.0;
		FullDuration = KnightAnimComp.GetFinalizedTotalDuration(SummitKnightFeatureTags::DualSlash, NAME_None, FullDuration);
		AnimComp.RequestFeature(SummitKnightFeatureTags::DualSlash, NAME_None, EBasicBehaviourPriority::Medium, this, FullDuration);

		Blade.Equip();

		TargetPlayer = Cast<AHazePlayerCharacter>(TargetComp.Target);
		if (TargetPlayer == nullptr)
			TargetPlayer = Game::Mio;
		if (!TargetComp.IsValidTarget(TargetPlayer) && TargetComp.IsValidTarget(TargetPlayer.OtherPlayer))
			TargetPlayer = TargetPlayer.OtherPlayer;

		USummitKnightSettings::SetRotationDuration(Owner, Settings.DualSlashTurnDuration, this);

		NumTriggeredImpacts = 0;
		ActionInfo.Reset(2);
		UAnimSequence Anim = KnightAnimComp.GetRequestedAnimation(SummitKnightFeatureTags::DualSlash, NAME_None);
		if (ensure(Anim != nullptr))
		{
			Anim.GetAnimNotifyStateTriggerTimes(UBasicAIActionAnimNotify, ActionInfo);
			Anim.GetAnimNotifyStateTriggerTimes(UBasicAITelegraphingAnimNotify, TelegraphInfo);
		}

		USummitKnightEventHandler::Trigger_OnDualSlashFirstTelegraph(Owner, FSummitKnightPlayerParams(TargetPlayer));
		bHasStartedSecondTelegraph = false;
		bHasStartedFirstSwing = false;
		bHasStartedSecondSwing = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		TargetComp.SetTarget(TargetPlayer.OtherPlayer);
		Owner.ClearSettingsByInstigator(this);
		Super::OnDeactivated();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!ActionInfo.IsValidIndex(NumTriggeredImpacts) || !TelegraphInfo.IsValidIndex(NumTriggeredImpacts))
			return;

		if (IsInTelegraphRange(ActiveDuration, NumTriggeredImpacts))
		{
			FVector TargetLoc = GetTargetLocation();
			DestinationComp.RotateTowards(TargetLoc);
		}

		if(!bHasStartedSecondTelegraph && NumTriggeredImpacts > 0 && ActiveDuration >= TelegraphInfo[NumTriggeredImpacts].TriggerTime)
		{
			bHasStartedSecondTelegraph = true;
			USummitKnightEventHandler::Trigger_OnDualSlashSecondTelegraph(Owner, FSummitKnightPlayerParams(TargetPlayer));
		}

		// Pre-fire impact events for lead-in juicyness
		if(!bHasStartedFirstSwing && IsInFirstSwingRange())
		{
			bHasStartedFirstSwing = true;
			USummitKnightEventHandler::Trigger_OnDualSlashFirstImpact(Owner);
		}

		if(!bHasStartedSecondSwing && IsInSecondSwingRange())
		{
			bHasStartedSecondSwing = true;
			USummitKnightEventHandler::Trigger_OnDualSlashSecondImpact(Owner);
		}

		if (IsInActionRange(ActiveDuration, NumTriggeredImpacts))
		{
			NumTriggeredImpacts++;
			FVector BladeDir = (Blade.TipLocation - Blade.HiltLocation).GetSafeNormal2D();
			
			// This behaviour is not in use, but let's clean it up anyway
			if (HasControl())
				CrumbLaunchShockwave(Blade.TipLocation, BladeDir);

			FVector BaseLoc = KnightComp.Arena.GetAtArenaHeight(Blade.HiltLocation);
			FVector TipLoc = KnightComp.Arena.GetAtArenaHeight(BaseLoc + BladeDir * Blade.BladeLength); // Ensure we get full length along arena even if animnotify is slightly misplaced
			float OuterRadius = Settings.GenericAttackBladeImpactKnockbackWidth;
			float KillRadius = Settings.GenericAttackBladeImpactKillWidth;
			for (AHazePlayerCharacter Player : Game::Players)
			{
				if (!Player.HasControl())
					continue;
				if (Player.ActorLocation.Z > Owner.ActorLocation.Z + 1000.0)
					continue;
				FVector PlayerArenaLoc = KnightComp.Arena.GetAtArenaHeight(Player.ActorLocation);
				if (!PlayerArenaLoc.IsInsideTeardrop2D(BaseLoc, TipLoc, OuterRadius, OuterRadius))
					continue;
				
				if (PlayerArenaLoc.IsInsideTeardrop2D(BaseLoc, TipLoc, KillRadius, KillRadius))
				{
					Player.DealTypedDamage(Owner, 1.0, EDamageEffectType::ObjectLarge, EDeathEffectType::ObjectLarge, false); // Splat!
					KnightComp.bDeathCouldHaveBeenDashAvoided[Player] = true;
				}
				
				FVector LineLoc;
				float Dummy;
				Math::ProjectPositionOnLineSegment(BaseLoc, TipLoc, PlayerArenaLoc, LineLoc, Dummy);
				FVector StumbleDir = (PlayerArenaLoc - LineLoc).GetNormalized2DWithFallback(-Player.ActorForwardVector);
				KnightComp.StumbleDragon(Player, StumbleDir * Settings.GenericAttackShockwaveStumbleDistance, 0.0, 0.5, 200.0);				
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbLaunchShockwave(FVector Location, FVector Direction)
	{
		UBasicAIProjectileComponent Projectile = Launcher.Launch(Direction * Settings.GenericAttackShockwaveMoveSpeed);
		Cast<ASummitKnightGenericAttackShockwave>(Projectile.Owner).LaunchLocal(Location, Owner);
	}

	FVector GetTargetLocation()
	{
		return TargetPlayer.ActorLocation + Owner.ActorRightVector * Owner.ActorLocation.Dist2D(TargetPlayer.ActorLocation) * 0.05;
	}

	bool IsInTelegraphRange(float Time, int Index) const
	{
		if (Time < TelegraphInfo[Index].TriggerTime)
			return false;
		if (Time > TelegraphInfo[Index].TriggerTime + TelegraphInfo[Index].Duration)
			return false;
		return true;
	}

	bool IsInActionRange(float Time, int Index) const
	{
		if (Time < ActionInfo[Index].TriggerTime)
			return false;
		if (Time > ActionInfo[Index].TriggerTime + ActionInfo[Index].Duration)
			return false;
		return true;
	}

	bool IsInFirstSwingRange() const
	{
		return NumTriggeredImpacts == 0 && ActiveDuration >= (TelegraphInfo[NumTriggeredImpacts].Duration - 0.15);
	}

	bool IsInSecondSwingRange() const
	{
		return NumTriggeredImpacts > 0 && (ActiveDuration - TelegraphInfo[0].Duration) >= (TelegraphInfo[NumTriggeredImpacts].TriggerTime - 0.15);
	}
}

