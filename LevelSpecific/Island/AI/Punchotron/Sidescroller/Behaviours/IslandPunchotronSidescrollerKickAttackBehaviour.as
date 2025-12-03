class UIslandPunchotronSidescrollerKickAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	default CapabilityTags.Add(BasicAITags::Attack);

	UGentlemanCostComponent GentCostComp;
	UBasicAIHealthComponent HealthComp;
	UIslandPunchotronAttackComponent AttackComp;
	UIslandPunchotronCooldownComponent CooldownComp;
	UIslandPunchotronSettings Settings;
	UPathfollowingSettings PathingSettings;
	private TPerPlayer<bool> HasHitPlayer;
	AAIIslandPunchotronSidescroller Punchotron;

	FBasicAIAnimationActionDurations AttackDurations;
	private const float TelegraphFraction = 0.3;
	private const float AnticipationFraction = 0.1;
	private const float ActionFraction = 0.1;
	private const float RecoveryFraction = 0.5;


	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		AttackComp = UIslandPunchotronAttackComponent::GetOrCreate(Owner);
		CooldownComp = UIslandPunchotronCooldownComponent::GetOrCreate(Owner);
		Settings = UIslandPunchotronSettings::GetSettings(Owner);
		PathingSettings = UPathfollowingSettings::GetSettings(Owner);
		HasHitPlayer[Game::Mio] = false;
		HasHitPlayer[Game::Zoe] = false;
		Punchotron = Cast<AAIIslandPunchotronSidescroller>(Owner);
	}
	
	bool WantsToAttack() const
	{
		if (!Cooldown.IsOver())
			return false; 
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.KickAttackRange))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
#if EDITOR
		if (Cast<AAIIslandPunchotronSidescroller>(Owner).bIsKickDisabled)
			return false;
#endif
		if (!WantsToAttack())
			return false;
		if(!GentCostComp.IsTokenAvailable(Settings.AttackGentlemanCost))
			return false;
		if (!IslandPunchotron::IsOnGround(Owner.ActorLocation, 20.0, PathingSettings.bIgnorePathfinding))
			return false;
		if (!CooldownComp.IsCooldownOver(Owner.Class))
			return false;
		if (AttackComp.bIsAttacking)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AttackComp.bIsAttacking = true;
		GentCostComp.ClaimToken(this, Settings.AttackGentlemanCost);
		
		AttackDurations.Telegraph =  Settings.KickAttackDuration * TelegraphFraction;
		AttackDurations.Anticipation = Settings.KickAttackDuration * AnticipationFraction;
		AttackDurations.Action = Settings.KickAttackDuration *  ActionFraction;
		AttackDurations.Recovery = Settings.KickAttackDuration * RecoveryFraction;
		AnimComp.RequestAction(FeatureTagIslandPunchotron::KickAttack, EBasicBehaviourPriority::Medium, this, AttackDurations);
		UIslandPunchotronEffectHandler::Trigger_OnKickAttackTelegraphStart(Owner);

		HasHitPlayer[Game::Mio] = false;
		HasHitPlayer[Game::Zoe] = false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Settings.KickAttackDuration)
			return true;		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		AttackComp.bIsAttacking = false;
		// Attack specific cooldown
		Cooldown.Set(Settings.KickAttackCooldown + Math::RandRange(-Settings.KickAttackCooldownDeviationRange, Settings.KickAttackCooldownDeviationRange));
		// Cooldown between each attack variant
		CooldownComp.SetCooldown(Owner.Class, Settings.GlobalAttackCooldown + Math::RandRange(-Settings.GlobalAttackCooldownDeviationRange, Settings.GlobalAttackCooldownDeviationRange));
		GentCostComp.ReleaseToken(this, Settings.AttackTokenCooldown);
		AnimComp.ClearFeature(this);
		UIslandPunchotronEffectHandler::Trigger_OnEyeTelegraphingStop(Owner);
		bHasStartedEyeTelegraphing = false;
	}

	private int HandleDamageDealing(FOverlapResultArray& Overlaps)
	{
		int NumHitPlayers = 0;

		for (bool HitPlayer : HasHitPlayer)
		{
			if (HitPlayer)
				NumHitPlayers++;
		}

		for (FOverlapResult Overlap : Overlaps.OverlapResults)
		{
			if (NumHitPlayers >= 2)
				break;
			if (Overlap.Actor == nullptr)
				continue;
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Overlap.Actor);
			if (Player == nullptr)
				continue;
			if (!Player.HasControl())
				continue;
			if (IslandPunchotron::IsPlayerDashing(Player))
				continue;
			if (HasHitPlayer[Player])
				continue;				

			HasHitPlayer[Player] = true;
			NumHitPlayers++;

			Player.DealTypedDamage(Owner, Settings.KickAttackDamage, EDamageEffectType::ObjectSmall, EDeathEffectType::ObjectSmall);

			float KnockdownDistance = Settings.KnockdownDistance;
			float KnockdownDuration = Settings.KnockdownDuration;;
			if (KnockdownDistance > 0.0)
			{
				FKnockdown Knockdown;
				Knockdown.Move = Owner.ActorForwardVector * KnockdownDistance;
				Knockdown.Duration = KnockdownDuration;
				Player.ApplyKnockdown(Knockdown);
			}
		}				

		return NumHitPlayers;
	}

	private bool HasHitBothPlayers()
	{
		return HasHitPlayer[Game::Mio] && HasHitPlayer[Game::Zoe];
	}

	bool bHasStartedEyeTelegraphing = false;

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (AttackDurations.IsInTelegraphRange(ActiveDuration) && !bHasStartedEyeTelegraphing)
		{
			UIslandPunchotronEffectHandler::Trigger_OnEyeTelegraphingStart(Owner, FIslandPunchotronEyeTelegraphingParams(Punchotron.EyeTelegraphingLocation));
			bHasStartedEyeTelegraphing = true;
		}
		else if (ActiveDuration > AttackDurations.Telegraph && bHasStartedEyeTelegraphing)
		{
			UIslandPunchotronEffectHandler::Trigger_OnEyeTelegraphingStop(Owner);
			bHasStartedEyeTelegraphing = false;
		}

		if (AttackDurations.IsInActionRange(ActiveDuration) && !HasHitBothPlayers())
		{
			UIslandPunchotronEffectHandler::Trigger_OnEyeTelegraphingStop(Owner);
			FVector HitSphereLocation = Cast<AHazeCharacter>(Owner).Mesh.GetSocketTransform(n"LeftFoot").GetLocation();
			
			FHazeTraceSettings Trace = Trace::InitObjectType(EObjectTypeQuery::PlayerCharacter);
			Trace.UseSphereShape(Settings.KickAttackHitRadius);
			FOverlapResultArray Overlaps = Trace.QueryOverlaps(HitSphereLocation);

			HandleDamageDealing(Overlaps);			

#if EDITOR
			// Draw hit sphere
			//Owner.bHazeEditorOnlyDebugBool = true;
			if (Owner.bHazeEditorOnlyDebugBool)
			{
				Debug::DrawDebugSphere(HitSphereLocation, Settings.KickAttackHitRadius, LineColor = FLinearColor::Red, Duration = 0.0);
				Debug::DrawDebugCapsule(Owner.ActorCenterLocation, Punchotron.CapsuleComponent.CapsuleHalfHeight, Punchotron.CapsuleComponent.CapsuleRadius, Punchotron.CapsuleComponent.WorldRotation);
			}

#endif	
		}

		if (ActiveDuration <  Settings.KickAttackDuration * (TelegraphFraction + AnticipationFraction) && TargetComp.HasValidTarget())
		{			
			DestinationComp.RotateTowards(TargetComp.Target);
		}
		

#if EDITOR
		// Draw attack range
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			FVector ToPlayer = (TargetComp.Target.ActorLocation - Owner.ActorLocation).GetSafeNormal();
			Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + ToPlayer * Settings.KickAttackRange, FLinearColor::Yellow, Duration = 3.0);
		}
#endif

	}		
	
}

