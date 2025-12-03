struct FIslandPunchotronJumpAttackActivationParams
{
	FVector AttackMove;
}

class UIslandPunchotronJumpAttackBehaviour : UBasicBehaviour
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
	private UPathfollowingSettings PathingSettings;
	private TPerPlayer<bool> HasHitPlayer;
	
	private FVector JumpDestination;
	private bool bHasTriggeredImpact = false;
	private bool bHasJumped = false;

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
	

	bool CanAttack() const
	{
		if (PathingSettings.bIgnorePathfinding)
			return false;
		if (!Settings.bIsJumpAttackEnabled)
			return false;
		if (bHasJumped)
			return false;
		if (AttackComp.bIsAttacking)
			return false;
		if (!CooldownComp.IsCooldownOver(Owner.Class))
			return false;
		if (!Cooldown.IsOver())
			return false; 
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.JumpAttackMaxRange))
			return false;
		if (Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.JumpAttackMinRange))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FIslandPunchotronJumpAttackActivationParams& Params) const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!CanAttack())
			return false;
		if(!GentCostComp.IsTokenAvailable(Settings.AttackGentlemanCost))
			return false;
		if (!IslandPunchotron::IsOnGround(Owner.ActorLocation, 40.0, PathingSettings.bIgnorePathfinding))
			return false;
		
		FVector AttackMove;
		if (!IslandPunchotron::CanPerformAttackMove(Owner.ActorLocation, TargetComp.Target.ActorLocation, Settings.JumpAttackTargetOffset, AttackMove, PathingSettings.bIgnorePathfinding))
			return false;
		AttackMove.Z = Settings.JumpAttackHeight;
		Params.AttackMove = AttackMove;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FIslandPunchotronJumpAttackActivationParams Params)
	{
		Super::OnActivated();
		AttackComp.bIsAttacking = true;
		GentCostComp.ClaimToken(this, Settings.AttackGentlemanCost);
		
		JumpDestination = Owner.ActorLocation + Params.AttackMove;
		AnimComp.RequestFeature(FeatureTagIslandPunchotron::JumpAttack, FeatureTagIslandPunchotron::JumpAttack, EBasicBehaviourPriority::Medium, this, Settings.JumpAttackDuration, Params.AttackMove);
		HasHitPlayer[Game::Mio] = false;
		HasHitPlayer[Game::Zoe] = false;
		bHasTriggeredImpact = false;
		bHasJumped = true; // for the time being, only one jump per fight.
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Settings.JumpAttackDuration)
			return true;
		if (!TargetComp.HasValidTarget())
			return false;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();		
		AttackComp.bIsAttacking = false;	
		Cooldown.Set(Settings.JumpAttackCooldown);
		// No global cooldown.
		GentCostComp.ReleaseToken(this, Settings.AttackTokenCooldown);
		AnimComp.ClearFeature(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Activate hitbox during time window
		if (ActiveDuration > Settings.JumpAttackDuration * Settings.JumpAttackHitFraction && ActiveDuration < Settings.JumpAttackDuration * Settings.JumpAttackHitEndFraction)
		{
				FVector ImpactLocation;
				ImpactLocation = Owner.ActorLocation + Owner.ActorForwardVector * Settings.JumpAttackHitOffset;
				int i = -1;
				for (AHazePlayerCharacter Player : Game::Players)
				{	
					i++;				
					if (!Player.HasControl())
						continue;
					if (HasHitPlayer[Player])
						continue;
								
					if (ImpactLocation.IsWithinDist(Player.ActorLocation, Settings.JumpAttackHitRadius))
					{
						HasHitPlayer[Player] = true;
						Player.DamagePlayerHealth(Settings.JumpAttackDamage); 

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
			Debug::DrawDebugSphere(ImpactLocation, Settings.JumpAttackHitRadius, LineColor = FLinearColor::Red, Duration = 0.0);
#endif

			SlideAwayFromTarget();
		}

		UpdateMovement();

#if EDITOR
		// Draw attack ranges
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			FVector ToPlayer = (TargetComp.Target.ActorLocation - Owner.ActorLocation).GetSafeNormal();
			Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + ToPlayer * Settings.JumpAttackMaxRange, FLinearColor::Purple, Duration = 3.0);
		}
#endif

	}

	private void UpdateMovement()
	{		
		if (TargetComp.HasValidTarget())
		{
			// Temp Hack
			if (ActiveDuration < 3.75) // TODO: replace with telegraph duration setting
				DestinationComp.RotateTowards(JumpDestination);			
		}

		if (Owner.ActorLocation.IsWithinDist2D(JumpDestination, 100.0) && !bHasTriggeredImpact)
		{
			bHasTriggeredImpact = true;
			UIslandPunchotronEffectHandler::Trigger_OnJumpAttackImpact(Owner, FIslandPunchotronJumpAttackImpactParams(Owner.ActorLocation));
		}
	}

	private void SlideAwayFromTarget()
	{
		if (TargetComp.HasValidTarget())
		{
			// Slide away from target if close
			float CloseRange = Settings.JumpAttackHitOffset;
			if (TargetComp.Target.ActorLocation.IsWithinDist(Owner.ActorLocation, CloseRange))
			 	DestinationComp.AddCustomAcceleration(-Owner.ActorForwardVector * 2000.0);
		}
	}

}

