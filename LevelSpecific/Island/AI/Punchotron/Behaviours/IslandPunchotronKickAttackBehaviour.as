class UIslandPunchotronKickAttackBehaviour : UBasicBehaviour
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

	private const float TelegraphFraction = 0.5;
	private const float AnticipationFraction = 0.0;
	private const float ActionFraction = 0.2;
	private const float RecoveryFraction = 0.2;


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
		if (AttackComp.bIsAttacking)
			return false;
		if (!CooldownComp.IsCooldownOver(Owner.Class))
			return false;
		if (!WantsToAttack())
			return false;
		if(!GentCostComp.IsTokenAvailable(Settings.AttackGentlemanCost))
			return false;
		if (!IslandPunchotron::IsOnGround(Owner.ActorLocation, 40.0, PathingSettings.bIgnorePathfinding))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AttackComp.bIsAttacking = true;
		GentCostComp.ClaimToken(this, Settings.AttackGentlemanCost);
		
		FBasicAIAnimationActionDurations AttackDurations;
		AttackDurations.Telegraph =  Settings.KickAttackDuration * TelegraphFraction;
		AttackDurations.Anticipation = Settings.KickAttackDuration * AnticipationFraction;
		AttackDurations.Action = Settings.KickAttackDuration *  ActionFraction;
		AttackDurations.Recovery = Settings.KickAttackDuration * RecoveryFraction;
		//AnimComp.RequestAction(FeatureTagIslandPunchotron::KickAttack, EBasicBehaviourPriority::Medium, this, AttackDurations);
		AnimComp.RequestFeature(FeatureTagIslandPunchotron::KickAttack, EBasicBehaviourPriority::Medium, this);

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
		Cooldown.Set(Settings.KickAttackCooldown);									// attack specific cooldown
		CooldownComp.SetCooldown(Owner.Class, Settings.GlobalAttackCooldown);		// cooldown between each attack variant
		GentCostComp.ReleaseToken(this, Settings.AttackTokenCooldown);
		AnimComp.ClearFeature(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration > Settings.KickAttackDuration * (TelegraphFraction + AnticipationFraction) &&
			ActiveDuration < Settings.KickAttackDuration * (TelegraphFraction + AnticipationFraction + ActionFraction) )
		{
			FVector HitSphereLocation = Cast<AHazeCharacter>(Owner).Mesh.GetSocketTransform(n"LeftToeBase").GetLocation();
			
			FHazeTraceSettings Trace = Trace::InitObjectType(EObjectTypeQuery::PlayerCharacter);
			Trace.UseSphereShape(Settings.KickAttackHitRadius);
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
				if (HasHitPlayer[Player])
					continue;					

				HasHitPlayer[Player] = true;
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
#if EDITOR
		// Draw hit sphere
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
			Debug::DrawDebugSphere(HitSphereLocation, Settings.KickAttackHitRadius, LineColor = FLinearColor::Red, Duration = 0.0);
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
			PrintScaled(f"KickAttack,  ActiveDuration={ActiveDuration:.2} out of " + Settings.KickAttackDuration, 0.0, Scale = 2.f);
			FVector ToPlayer = (TargetComp.Target.ActorLocation - Owner.ActorLocation).GetSafeNormal();
			Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + ToPlayer * Settings.KickAttackRange, FLinearColor::Yellow, Duration = 3.0);
		}
#endif

	}		
	
}

