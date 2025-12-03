struct FIslandPunchotronBackhandAttackActivationParams
{
	FVector AttackMove;
}

class UIslandPunchotronBackhandAttackBehaviour : UBasicBehaviour
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

	private FVector Destination;

	private const float TelegraphFraction = 0.4;
	private const float AnticipationFraction = 0.0;
	private const float ActionFraction = 0.3;
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
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.BackhandAttackRange))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FIslandPunchotronBackhandAttackActivationParams& Params) const
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

		FVector AttackMove;		
		if (!IslandPunchotron::CanPerformAttackMove(Owner.ActorLocation, TargetComp.Target.ActorLocation, Settings.BackhandAttackTargetOffset, AttackMove, PathingSettings.bIgnorePathfinding))
			return false;
		AttackMove.Z = 0;
		Params.AttackMove = AttackMove;

		return true;
	}
	
	UFUNCTION(BlueprintOverride)
	void OnActivated(FIslandPunchotronBackhandAttackActivationParams Params)
	{
		Super::OnActivated();
		AttackComp.bIsAttacking = true;
		GentCostComp.ClaimToken(this, Settings.AttackGentlemanCost);

		Destination = Owner.ActorLocation + Params.AttackMove;
		
		FBasicAIAnimationActionDurations AttackDurations;
		AttackDurations.Telegraph =  Settings.HaywireAttackDuration * TelegraphFraction;
		AttackDurations.Anticipation = Settings.HaywireAttackDuration * AnticipationFraction;
		AttackDurations.Action = Settings.HaywireAttackDuration *  ActionFraction;
		AttackDurations.Recovery = Settings.HaywireAttackDuration * RecoveryFraction;
		//AnimComp.RequestAction(FeatureTagIslandPunchotron::BackhandAttack, EBasicBehaviourPriority::Medium, this, AttackDurations, Params.AttackMove, false);
		AnimComp.RequestFeature(FeatureTagIslandPunchotron::BackhandAttack, EBasicBehaviourPriority::Medium, this, 0.0, Params.AttackMove, false);
		
		HasHitPlayer[Game::Mio] = false;
		HasHitPlayer[Game::Zoe] = false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Settings.BackhandAttackDuration)
			return true;		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		AttackComp.bIsAttacking = false;
		Cooldown.Set(Settings.BackhandAttackCooldown);								// attack specific cooldown
		CooldownComp.SetCooldown(Owner.Class, Settings.GlobalAttackCooldown);		// cooldown between each attack variant
		GentCostComp.ReleaseToken(this, Settings.AttackTokenCooldown);
		AnimComp.ClearFeature(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		//SlideAwayFromTarget();
		UpdateMovement();

		if (ActiveDuration > Settings.BackhandAttackDuration * Settings.BackhandAttackHitFraction && ActiveDuration < Settings.BackhandAttackDuration * Settings.BackhandAttackHitEndFraction)
		{
			FVector ImpactLocation;
			ImpactLocation = Owner.ActorLocation + Owner.ActorForwardVector * Settings.BackhandAttackHitOffset;
			for (AHazePlayerCharacter Player : Game::Players)
			{	
				if (!Player.HasControl())
					continue;
				if (HasHitPlayer[Player])
					continue;
							
				// Note that damage dealing is networked, though worst case a player on our remote side won't get hit at 
				// all if (ActiveDuration > PunchotronSettings.AttackDuration * PunchotronSettings.AttackHitFraction) 
				// never becomes true before deactivating. Due to the likely volume of attacks we ignore this.
				if (ImpactLocation.IsWithinDist(Player.ActorLocation, Settings.BackhandAttackHitRadius))
				{
					HasHitPlayer[Player] = true;
					Player.DamagePlayerHealth(Settings.BackhandAttackDamage); 

					float KnockdownDistance = Settings.KnockdownDistance;
					float KnockdownDuration = Settings.KnockdownDuration;;
					if (KnockdownDistance > 0.0)
					{
						FKnockdown Knockdown;
						Knockdown.Move = Owner.ActorForwardVector * KnockdownDistance;
						Knockdown.Duration = KnockdownDuration;
						Player.ApplyKnockdown(Knockdown);
					}

					AttackComp.bEnableTaunt = true;
				}
			}
#if EDITOR
		// Draw hit sphere
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool) 
			Debug::DrawDebugSphere(ImpactLocation, Settings.BackhandAttackHitRadius, LineColor = FLinearColor::Red, Duration = 0.0);
#endif			
		}


#if EDITOR
		// Draw attack ranges
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			PrintScaled(f"BackhandAttack, ActiveDuration={ActiveDuration:.2} out of " + Settings.BackhandAttackDuration, 0.0, Scale = 2.f);
			FVector ToPlayer = (TargetComp.Target.ActorLocation - Owner.ActorLocation).GetSafeNormal();
			Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + ToPlayer * Settings.JumpAttackMaxRange, FLinearColor::Purple, Duration = 3.0);
			Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + ToPlayer * Settings.SpinningAttackMaxRange, FLinearColor::DPink, Duration = 3.0);
			Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + ToPlayer * Settings.HaywireMaxAttackRange, FLinearColor::Blue, Duration = 3.0);
			Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + ToPlayer * Settings.KickAttackRange, FLinearColor::Yellow, Duration = 3.0);
			Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + ToPlayer * Settings.BackhandAttackRange, FLinearColor::Gray, Duration = 3.0);
		}
#endif

	}

	private void UpdateMovement()
	{		
		if (TargetComp.HasValidTarget())
		{			
			if (ActiveDuration < Settings.HaywireAttackDuration * TelegraphFraction)
				DestinationComp.RotateTowards(Destination);
		}
	}

	private void SlideAwayFromTarget()
	{
		if (TargetComp.HasValidTarget())
		{
			// Slide away from target if close
			float CloseRange = 100.0;
			if (TargetComp.Target.ActorLocation.IsWithinDist(Owner.ActorLocation, CloseRange))
			 	DestinationComp.AddCustomAcceleration(-Owner.ActorForwardVector * 2000.0);
		}
	}

}

