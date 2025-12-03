class UIslandWalkerFireBurstBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 
	default Requirements.Add(EBasicBehaviourRequirement::Perception);

	UIslandWalkerSettings Settings;

	AHazePlayerCharacter TargetPlayer;
	UTargetTrailComponent TargetTrail;
	UIslandWalkerComponent WalkerComp;
	UIslandWalkerFlameThrowerComponent FlameThrower;
	UIslandWalkerSwivelComponent Swivel;
	UIslandWalkerAnimationComponent WalkerAnimComp;

	TArray<AHazePlayerCharacter> AvailableTargets;
	FVector Destination;

	float SwivelTime = 0.0;
	FBasicAIAnimationActionDurations Durations;
	bool bPreAttackSwivelling = false;
	bool bSlam = false;
	bool bSprayingFire = false;
	AIslandWalkerFirewall FireWall;

	FHazeAcceleratedFloat AccYawSpeed;

	TArray<UIslandWalkerStompComponent> Stomps;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		WalkerComp = UIslandWalkerComponent::Get(Owner);
		Swivel = UIslandWalkerSwivelComponent::Get(Owner);
		Settings = UIslandWalkerSettings::GetSettings(Owner);
		WalkerAnimComp = UIslandWalkerAnimationComponent::Get(Owner);
		Owner.GetComponentsByClass(Stomps);
		UTargetTrailComponent::GetOrCreate(Game::Mio);
		UTargetTrailComponent::GetOrCreate(Game::Zoe);

		UIslandWalkerNeckRoot::Get(Owner).OnHeadSetup.AddUFunction(this, n"OnHeadSetup");
	}

	UFUNCTION()
	private void OnHeadSetup(AIslandWalkerHead Head)
	{
		FlameThrower = UIslandWalkerFlameThrowerComponent::Get(Head);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{		
		if(!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (FlameThrower == nullptr)
			return false;
		if (WalkerComp.LaserAttackCount < WalkerComp.FireBurstCount)
			return false; // Number of slams cannot exceed number of laser attacks by more than one
		if (!WalkerComp.CanPerformAttack(EISlandWalkerAttackType::FireBurst))
			return false;
 		return true;		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > SwivelTime + Durations.GetTotal())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		WalkerComp.LastAttack = EISlandWalkerAttackType::FireBurst;
		WalkerComp.FireBurstCount++;

		TargetPlayer = Cast<AHazePlayerCharacter>(TargetComp.Target);
		TargetTrail = UTargetTrailComponent::Get(TargetPlayer);

		Durations.Telegraph = Settings.FireBurstTelegraphDuration;
		Durations.Anticipation = Settings.FireBurstAnticipationDuration;
		Durations.Action = Settings.FireBurstActionDuration;
		Durations.Recovery = Settings.FireBurstRecoverDuration;
		WalkerAnimComp.FinalizeDurations(FeatureTagWalker::FireBurst, NAME_None, Durations);
		
		// Swivel for this long or until we get near enough to target
		SwivelTime = 3.0;
		bPreAttackSwivelling = true;

		Destination = TargetPlayer.ActorLocation + TargetTrail.GetAverageVelocity(0.5) * Settings.FireBurstTargetPredictionTime;
		AvailableTargets = Game::Players;
		bSprayingFire = false;
		bSlam = false;

		AccYawSpeed.SnapTo(Swivel.SwivelVelocity);

		UIslandWalkerHeadEffectHandler::Trigger_OnFireBurstTelegraph(Cast<AHazeActor>(FlameThrower.Owner), FIslandWalkerSprayFireParams(FlameThrower));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		if (ActiveDuration > Settings.FireBurstTelegraphDuration)
			Cooldown.Set(Settings.FireBurstCooldown);
		if (bSprayingFire)
			StopSprayingFire();
		Owner.ClearSettingsByInstigator(this);
		AnimComp.ClearFeature(this);	
		WalkerAnimComp.HeadAnim.ClearFeature(this);	

		// Allow new target selection
		TargetComp.Target = nullptr;
	}

	float GetDeltaYawTo(FVector Dest) const
	{
		float DestYaw = (Dest - Swivel.WorldLocation).Rotation().Yaw;
		return FRotator::NormalizeAxis(DestYaw - Swivel.WorldRotation.Yaw);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (bPreAttackSwivelling) 
		{
			// Should we start attack?
			if ((ActiveDuration > SwivelTime) ||  // Past max time
				(Math::Abs(GetDeltaYawTo(TargetComp.Target.ActorLocation)) < Settings.FireBurstMaxAngle)) // Near enough
			{
				bPreAttackSwivelling = false;
				SwivelTime = ActiveDuration;
				AnimComp.RequestAction(FeatureTagWalker::FireBurst, EBasicBehaviourPriority::Medium, this, Durations);
				WalkerAnimComp.HeadAnim.RequestAction(FeatureTagWalker::FireBurst, EBasicBehaviourPriority::Medium, this, Durations);
			}
		}

		if(ActiveDuration < SwivelTime + Durations.Telegraph)
		{
			// Swivel towards target
			Destination = TargetPlayer.ActorLocation + TargetTrail.GetAverageVelocity(0.5) * Settings.FireBurstTargetPredictionTime;
			float DeltaYaw = GetDeltaYawTo(Destination);
			if (Math::Abs(DeltaYaw) > 10.0)
				AccYawSpeed.AccelerateTo(Math::Sign(DeltaYaw) * 90.0, 2.0, DeltaTime);
			else
				AccYawSpeed.AccelerateTo(0.0, 1.0, DeltaTime);
			Swivel.Swivel(AccYawSpeed.Value);
		}

		if (!bSlam && Durations.IsInAnticipationRange(ActiveDuration - SwivelTime))
			DealSlamDamage(); // Note that this is dealt during anticipation currently, action range is for spraying fire

		if (!bSprayingFire && Durations.IsInActionRange(ActiveDuration - SwivelTime))
			StartSprayingFire();
		if (bSprayingFire)
		{	
			FVector SprayDir = FlameThrower.WorldRotation.ForwardVector.GetSafeNormal2D();
			FlameThrower.TargetLocation += SprayDir * Settings.FireBurstSpraySpeed * DeltaTime;	
			if (Durations.IsInRecoveryRange(ActiveDuration - SwivelTime))			
				StopSprayingFire();
		}

		if (ActiveDuration > SwivelTime)
		{
			// Check if squashed by legs slamming down or moving back
			float AttackTime = ActiveDuration - SwivelTime;
			if ((AttackTime < Durations.Telegraph + Durations.Anticipation * 0.25) || (AttackTime > Durations.PreRecoveryDuration + Durations.Recovery * 0.25))
			{
				for (UIslandWalkerStompComponent Stomp : Stomps)
				{
					Stomp.UpdateStomp(DeltaTime);
					Stomp.StompPlayers();
				}
			}
		}
	}

	void StartSprayingFire()
	{
		bSprayingFire = true;
		FVector SprayDir = FlameThrower.WorldRotation.ForwardVector.GetSafeNormal2D();
		FlameThrower.TargetLocation = FlameThrower.LaunchLocation + SprayDir * 200.0;
		FlameThrower.TargetLocation.Z = WalkerComp.ArenaLimits.Height;
		FireWall = Cast<AIslandWalkerFirewall>(FlameThrower.Launch(SprayDir * Settings.FireBurstSpraySpeed).Owner);
		FireWall.StartSprayingFire(Owner, FlameThrower, Settings.FireBurstDamagePerSecond, 3.0, Settings.FirewallDamageShenanigansHeight);
		WalkerComp.ArenaLimits.DisableRespawnPointsAtSide(FlameThrower.TargetLocation + SprayDir * 1000.0, this);		

		UIslandWalkerHeadEffectHandler::Trigger_OnFireBurstStart(Cast<AHazeActor>(FlameThrower.Owner), FIslandWalkerSprayFireParams(FlameThrower));
	}

	void StopSprayingFire()
	{
		FireWall.StopSprayingFire(Settings.FirewallDissipateDuration);
		bSprayingFire = false;
		WalkerComp.ArenaLimits.EnableAllRespawnPoints(this);		

		UIslandWalkerHeadEffectHandler::Trigger_OnFireBurstStop(Cast<AHazeActor>(FlameThrower.Owner));
	}

	void DealSlamDamage()
	{
		FVector Epicenter = Owner.ActorTransform.TransformPosition(Settings.FireBurstDamageAreaOffset);
		for(int i = AvailableTargets.Num() - 1; i >= 0; i--)
		{
			AHazePlayerCharacter Player = AvailableTargets[i];
			if (!IsInDamageZone(Player.ActorLocation, Epicenter))
				continue;

			Player.DealTypedDamage(Owner, Settings.FireBurstSlamDamage, EDamageEffectType::ObjectLarge, EDeathEffectType::ObjectLarge);

			FKnockdown Knockdown;
			FVector Dir = (Player.ActorLocation - Owner.ActorLocation).ConstrainToPlane(Player.ActorUpVector).GetNormalizedWithFallback(-Player.ActorForwardVector);
			float Force = Math::Max(2000 - Owner.ActorLocation.Distance(Player.ActorLocation), 0);
			Knockdown.Move = Dir * Force;
			Knockdown.Duration = 1.0;
			Player.ApplyKnockdown(Knockdown);
			UPlayerDamageEventHandler::Trigger_TakeBigDamage(Player);

			AvailableTargets.RemoveAt(i);
		}

		// Kill any minions foolish enough to be in the way
		UHazeTeam BuzzerTeam = HazeTeam::GetTeam(IslandBuzzerTags::IslandBuzzerTeam);
		TArray<UBasicAIHealthComponent> FormerMinions;
		if(BuzzerTeam != nullptr && BuzzerTeam.GetMembers().Num() > 0)
		{
			for(AHazeActor Buzzer: BuzzerTeam.GetMembers())
			{
				if (Buzzer == nullptr)
					continue;
				if (!IsInDamageZone(Buzzer.ActorLocation, Epicenter))
					continue;
				UBasicAIHealthComponent HealthComp = UBasicAIHealthComponent::Get(Buzzer);
				if((HealthComp != nullptr) && HealthComp.IsAlive())
					FormerMinions.Add(HealthComp);
			}
		}
		for (UBasicAIHealthComponent VictimHealth : FormerMinions)
		{
			VictimHealth.TakeDamage(BIG_NUMBER, EDamageType::Default, Owner);
		}

#if EDITOR
		if (Owner.bHazeEditorOnlyDebugBool)
			Debug::DrawDebugCylinder(Epicenter, Epicenter + FVector(0,0,Settings.FireBurstDamageAreaHeight), Settings.FireBurstDamageAreaRadius, 24, FLinearColor::Red, 10.0);		
#endif		
	}

	bool IsInDamageZone(FVector Loc, FVector Epicenter)
	{
		if (Loc.Z > Epicenter.Z + Settings.FireBurstDamageAreaHeight) 
			return false;
		if (!Loc.IsWithinDist2D(Epicenter, Settings.FireBurstDamageAreaRadius))
			return false;
		return true;
	}
}