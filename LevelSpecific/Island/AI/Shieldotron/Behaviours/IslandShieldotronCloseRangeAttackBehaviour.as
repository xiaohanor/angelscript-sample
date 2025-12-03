class UIslandShieldotronCloseRangeAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);


	default CapabilityTags.Add(BasicAITags::Attack);
	default CapabilityTags.Add(n"CloseRangeAttack");

	UGentlemanCostComponent GentCostComp;
	USceneComponent Weapon;
	UBasicAIHealthComponent HealthComp;
	UIslandShieldotronJumpComponent JumpComp;

	UIslandShieldotronSettings Settings;

	AHazePlayerCharacter TargetPlayer;

	float NextFireTime = 0.0;	
	int NumBurstProjectiles = 1;
	int NumFiredProjectiles = 0;
	bool bHasTriggeredTelegraph = false;
	bool bHasCheckedDamageOverlap = false;

	TSet<AHazePlayerCharacter> HasHitSet;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		Weapon = Cast<AAIIslandShieldotron>(Owner).BlastAttackComp;
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		JumpComp = UIslandShieldotronJumpComponent::GetOrCreate(Owner);
		
		Settings = UIslandShieldotronSettings::GetSettings(Owner);
	}

	bool WantsToAttack() const
	{
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;		
		if (!TargetComp.HasValidTarget())
			return false;
		if (!TargetComp.HasGeometryVisibleTarget())
			return false;
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.CloseRangeAttackMaxActivationRange))
			return false;
		if (Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.CloseRangeAttackMinActivationRange))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!Settings.bHasCloseRangeAttack)
			return false;
		if (JumpComp.bIsJumping)
			return false;
		if (!WantsToAttack())
			return false;
		if(!GentCostComp.IsTokenAvailable(Settings.AttackGentlemanCost))
			return false;
		if (!IsOnSameElevation())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Settings.CloseRangeAttackActionDuration + Settings.CloseRangeAttackTelegraphDuration + Settings.CloseRangeAttackRecoveryDuration)
			return true;
		if (!IsOnSameElevation() && ActiveDuration < Settings.CloseRangeAttackTelegraphDuration)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();		
		
		GentCostComp.ClaimToken(this, Settings.AttackGentlemanCost);

		NumFiredProjectiles = 0;
		NextFireTime = Time::GameTimeSeconds + Settings.CloseRangeAttackTelegraphDuration + Math::RandRange(0.0, 0.25);
		
		AnimComp.RequestFeature(FeatureTagIslandSecurityMech::BlastAttackCharge, EBasicBehaviourPriority::Medium, this);

		Owner.BlockCapabilities(n"MortarAttack", this); // Let attack finish before mortar attack is executed.
		Owner.BlockCapabilities(n"OrbAttack", this); // Let attack finish before orb attack is executed.

		// Nearest player serves as target for the attack
		if (Owner.ActorLocation.DistSquared(Game::Mio.ActorLocation) < Owner.ActorLocation.DistSquared(Game::Zoe.ActorLocation) )
			TargetPlayer = Game::Mio;
		else
			TargetPlayer = Game::Zoe;

		HasHitSet.Reset();
	}	

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GentCostComp.ReleaseToken(this);

		Cooldown.Set(Settings.CloseRangeAttackCooldown + Math::RandRange(-0.25, 0.25));
		bHasTriggeredTelegraph = false;
		bHasCheckedDamageOverlap = false;
		AnimComp.ClearFeature(this);
		DeactivateBehaviour(); // Ensures anim instance has a tick to update current tag.
		Owner.UnblockCapabilities(n"MortarAttack", this);
		Owner.UnblockCapabilities(n"OrbAttack", this);
		UIslandShieldotronEffectHandler::Trigger_OnCloseRangeAttackTelegraphStop(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Start telegraphing after 0.25s
		if (ActiveDuration > 0.25 && !bHasTriggeredTelegraph)
		{
			UIslandShieldotronEffectHandler::Trigger_OnCloseRangeAttackTelegraphStart(Owner, FIslandShieldotronCloseRangeAttackTelegraphParams(Weapon, Settings.CloseRangeAttackTelegraphDuration));
			bHasTriggeredTelegraph = true;
		}

		// Permit rotating during telegraphing phase
		if (ActiveDuration < Settings.CloseRangeAttackTelegraphDuration)
		{
			DestinationComp.RotateTowards(TargetPlayer);
			if (TargetPlayer.ActorLocation.Dist2D(Owner.ActorLocation) > Settings.CloseRangeAttackMinChaseRange)
				DestinationComp.MoveTowards(TargetPlayer.ActorLocation, Settings.ChaseMoveSpeed * 1.0);
			return;
		}
		
		if (NumFiredProjectiles < NumBurstProjectiles && NextFireTime < Time::GameTimeSeconds)
		{
			// Blast off
			NextFireTime += BIG_NUMBER;
			AnimComp.RequestFeature(FeatureTagIslandSecurityMech::BlastAttackRelease, EBasicBehaviourPriority::Medium, this);
			Blast();
		}
		else if (ActiveDuration > Settings.CloseRangeAttackTelegraphDuration + (Settings.CloseRangeAttackActionDuration * 0.55))
		{
			// Check for player hits and deal damage

			if (ActiveDuration > Settings.CloseRangeAttackTelegraphDuration + (Settings.CloseRangeAttackActionDuration * 0.65) && bHasCheckedDamageOverlap)
				return;
			bHasCheckedDamageOverlap = true;				

			// Check if player is within attack radius and deal damage, draw debug sphere
			float HitSphereRadius = Settings.CloseRangeAttackHitSphereRadius;
			FVector HitSphereLocation = Owner.ActorCenterLocation + Owner.ActorForwardVector * HitSphereRadius * 0.9;
			
			//Debug::DrawDebugSphere(HitSphereLocation, HitSphereRadius, LineColor = FLinearColor::Red);

			FHazeTraceSettings Trace = Trace::InitObjectType(EObjectTypeQuery::PlayerCharacter);
			Trace.UseSphereShape(HitSphereRadius);
			FOverlapResultArray Overlaps = Trace.QueryOverlaps(HitSphereLocation);
			for (FOverlapResult Overlap : Overlaps.OverlapResults)
			{
				if (Overlap.Actor == nullptr)
					continue;
				AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Overlap.Actor);
				if (Player == nullptr)
					continue;
				if (!Player.HasControl())
					continue;
				if (HasHitSet.Contains(Player))
					continue;

				HasHitSet.Add(Player);
				Player.DealTypedDamage(Owner, Settings.CloseRangeAttackDamage, EDamageEffectType::ElectricityImpact, EDeathEffectType::ElectricityImpact);	 

				float KnockdownDistance = Settings.CloseRangeAttackKnockdownDistance;
				float KnockdownDuration = Settings.CloseRangeAttackKnockdownDuration;;
				if (KnockdownDistance > 0.0)
				{
					FKnockdown Knockdown;
					Knockdown.Move = Owner.ActorForwardVector * KnockdownDistance;
					Knockdown.Duration = KnockdownDuration;
					Player.ApplyKnockdown(Knockdown);
				}
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void Blast()
	{
		NumFiredProjectiles++;
		
		float HitSphereRadius = Settings.CloseRangeAttackHitSphereRadius;
		FVector HitSphereLocation = Owner.ActorCenterLocation + Owner.ActorForwardVector * HitSphereRadius;
		UIslandShieldotronEffectHandler::Trigger_OnCloseRangeAttackLaunch(Owner, FIslandShieldotronCloseRangeAttackParams(Weapon, HitSphereLocation, Settings.CloseRangeAttackActionDuration));

		UIslandShieldotronPlayerEffectHandler::Trigger_OnLaunchCloseRangeBlastAttack(Game::Zoe, FIslandShieldotronCloseRangeBlastAttackPlayerEventData(Owner, TargetComp.Target));
		UIslandShieldotronPlayerEffectHandler::Trigger_OnLaunchCloseRangeBlastAttack(Game::Mio, FIslandShieldotronCloseRangeBlastAttackPlayerEventData(Owner, TargetComp.Target));
	}


	bool IsOnSameElevation() const
	{
		if (Math::Abs(TargetComp.Target.ActorLocation.Z - Owner.ActorLocation.Z) > 20 && UPlayerMovementComponent::Get(TargetComp.Target).IsOnAnyGround())
			return false;

		return true;
	}

} 