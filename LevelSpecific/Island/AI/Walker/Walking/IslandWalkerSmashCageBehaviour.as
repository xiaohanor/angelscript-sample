struct FIslandWalkerSmashCageParams
{
	bool bLeftCage;
}

class UIslandWalkerSmashCageBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 
	default Requirements.Add(EBasicBehaviourRequirement::Perception);

	UIslandWalkerSettings Settings;
	UIslandWalkerComponent WalkerComp;
	UIslandWalkerAnimationComponent WalkerAnimComp;
	UIslandWalkerSwivelComponent Swivel;
	UIslandWalkerFlameThrowerComponent GasOrifice;
	
	float PhaseStartTime = -BIG_NUMBER;
	float TurnDuration;
	FBasicAIAnimationActionDurations AttackDurations;
	bool bAttackStarted = false;
	bool bLaserPowerUp = false;
	bool bLaserFiring = false;
	bool bAttackLeftCage = false;

	FHazeAcceleratedVector LaserTargetLoc;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		WalkerAnimComp = UIslandWalkerAnimationComponent::Get(Owner);
		WalkerComp = UIslandWalkerComponent::Get(Owner);
		Settings = UIslandWalkerSettings::GetSettings(Owner);
		Swivel = UIslandWalkerSwivelComponent::Get(Owner);

		UIslandWalkerPhaseComponent::Get(Owner).OnPhaseChange.AddUFunction(this, n"OnPhaseChange");
		UIslandWalkerNeckRoot::Get(Owner).OnHeadSetup.AddUFunction(this, n"OnHeadSetup");
	}

	UFUNCTION()
	private void OnHeadSetup(AIslandWalkerHead Head)
	{
		GasOrifice = UIslandWalkerFlameThrowerComponent::Get(Head);
	}
	
	UFUNCTION()
	private void OnPhaseChange(EIslandWalkerPhase NewPhase)
	{
		if (NewPhase == EIslandWalkerPhase::Walking)
			PhaseStartTime = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FIslandWalkerSmashCageParams& OutParams) const
	{
		if(!Super::ShouldActivate())
			return false;
		if (Time::GameTimeSeconds > PhaseStartTime + 1.0)
			return false; // Only allow this at the very start of walking phase	
		if (WalkerComp.LastAttack != EISlandWalkerAttackType::None)
			return false; // Don't use this when we've started other attacks
		// TODO: Might want to add conditions on actor location/rotation
		AHazePlayerCharacter LeftPlayer = WalkerComp.ArenaLimits.GetPlayerInLeftCage();
		if (LeftPlayer != nullptr)
		{
			OutParams.bLeftCage = true;
			return true;
		}
		AHazePlayerCharacter RightPlayer = WalkerComp.ArenaLimits.GetPlayerInRightCage();
		if (RightPlayer != nullptr)
		{
			OutParams.bLeftCage = false;
			return true;
		}
		return false;		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > TurnDuration + AttackDurations.GetTotal())	
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FIslandWalkerSmashCageParams Params)
	{
		Super::OnActivated();
		bAttackLeftCage = Params.bLeftCage;

		FName TurnSubTag = (Params.bLeftCage ? SubTagWalkerSmashCage::Left : SubTagWalkerSmashCage::Right);
		TurnDuration = WalkerAnimComp.GetFinalizedTotalDuration(FeatureTagWalker::SmashCage, TurnSubTag, 0.0);
		AnimComp.RequestFeature(FeatureTagWalker::SmashCage, TurnSubTag, EBasicBehaviourPriority::Medium, this, TurnDuration);
		WalkerAnimComp.HeadAnim.RequestFeature(FeatureTagWalker::SmashCage, TurnSubTag, EBasicBehaviourPriority::Medium, this, TurnDuration);

		bAttackStarted = false;
		bLaserPowerUp = false;
		bLaserFiring = false;
		WalkerAnimComp.FinalizeDurations(FeatureTagWalker::SmashCage, SubTagWalkerSmashCage::Attack, AttackDurations);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		AnimComp.ClearFeature(this);	
		WalkerAnimComp.HeadAnim.ClearFeature(this);	
		if (bLaserFiring)
			UIslandWalkerHeadEffectHandler::Trigger_OnFireBurstStop(GasOrifice.LauncherActor);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Swivel.Realign(TurnDuration, DeltaTime);

		if (!bAttackStarted && (ActiveDuration > TurnDuration))
		{
			bAttackStarted = true;
			AnimComp.RequestAction(FeatureTagWalker::SmashCage, SubTagWalkerSmashCage::Attack, EBasicBehaviourPriority::Medium, this, AttackDurations);			
			WalkerAnimComp.HeadAnim.RequestAction(FeatureTagWalker::SmashCage, SubTagWalkerSmashCage::Attack, EBasicBehaviourPriority::Medium, this, AttackDurations);			
		}	
		if (bAttackStarted) 
		{
			float AttackDuration = ActiveDuration - TurnDuration;
			if (!bLaserPowerUp && AttackDurations.IsInAnticipationRange(AttackDuration))
			{
				bLaserPowerUp = true;
				UIslandWalkerHeadEffectHandler::Trigger_OnFireBurstTelegraph(GasOrifice.LauncherActor, FIslandWalkerSprayFireParams(GasOrifice));
			}
			if (!bLaserFiring && AttackDurations.IsInActionRange(AttackDuration))
			{
				bLaserFiring = true;
				bLaserPowerUp = false;
				UIslandWalkerHeadEffectHandler::Trigger_OnFireBurstStart(GasOrifice.LauncherActor, FIslandWalkerSprayFireParams(GasOrifice));
				LaserTargetLoc.SnapTo(WalkerComp.Laser.WorldLocation + WalkerComp.Laser.ForwardVector * 2000.0);
				WalkerComp.Laser.EndLocation = LaserTargetLoc.Value;
			}
			if (bLaserFiring && AttackDurations.IsInRecoveryRange(AttackDuration))
			{
				bLaserFiring = false;	
				bLaserPowerUp = false;
				UIslandWalkerHeadEffectHandler::Trigger_OnFireBurstStop(GasOrifice.LauncherActor);
			}

			if (bLaserFiring)
			{
				FVector EmissionLoc = WalkerComp.Laser.WorldLocation;
				AHazePlayerCharacter CagePlayer	= (bAttackLeftCage ? WalkerComp.ArenaLimits.GetPlayerInLeftCage() : WalkerComp.ArenaLimits.GetPlayerInRightCage());
				FVector TargetDir = WalkerComp.Laser.ForwardVector;
				if (CagePlayer != nullptr)
					TargetDir = (CagePlayer.ActorCenterLocation - EmissionLoc).GetSafeNormal();
				LaserTargetLoc.AccelerateTo(EmissionLoc + TargetDir * 2000.0, 0.5, DeltaTime);

				FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
				Trace.UseLine();
				Trace.IgnoreActor(Owner);
				FVector EmissionDir = (LaserTargetLoc.Value - EmissionLoc).GetSafeNormal();
				FHitResult Obstruction = Trace.QueryTraceSingle(EmissionLoc + EmissionDir * 500.0, LaserTargetLoc.Value);
				WalkerComp.Laser.EndLocation = LaserTargetLoc.Value;
				if (Obstruction.bBlockingHit)
					WalkerComp.Laser.EndLocation = Obstruction.Location;

				if (CagePlayer != nullptr)
				{
					// Caged player can't hide!
					CagePlayer.DealTypedDamageBatchedOverTime(Owner, 5.0 * DeltaTime, EDamageEffectType::FireImpact, EDeathEffectType::FireImpact);
					CagePlayer.ApplyAdditiveHitReaction(EmissionDir, EPlayerAdditiveHitReactionType::Small);
					UPlayerDamageEventHandler::Trigger_TakeDamageOverTime(CagePlayer);
				}
			}
		}
	}
}
