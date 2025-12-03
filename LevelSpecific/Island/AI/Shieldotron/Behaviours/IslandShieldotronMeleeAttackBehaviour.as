class UIslandShieldotronMeleeAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	default CapabilityTags.Add(BasicAITags::Attack);
	default CapabilityTags.Add(n"MeleeAttack");

	UIslandShieldotronSettings Settings;

	UIslandShieldotronJumpComponent JumpComp;

	AHazePlayerCharacter TargetPlayer;

	TSet<AHazePlayerCharacter> HasHitSet;
	float ProximityTimer = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		JumpComp = UIslandShieldotronJumpComponent::GetOrCreate(Owner);
		Settings = UIslandShieldotronSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;

		if (!Settings.bHasMeleeAttack)
			return false;

		if (!TargetComp.HasValidTarget())
			return false;

		if (ProximityTimer < Settings.MeleeAttackActivationTime)
			return false;

		if (JumpComp.bIsJumping)
			return false;

		return true;
	}



	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;

		if (ActiveDuration > Settings.MeleeAttackDuration + 0.3) // Extra time for letting animations blend
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		Owner.BlockCapabilities(n"MortarAttack", this); // Let melee attack finish before mortar attack is executed.
		Owner.BlockCapabilities(n"CloseRangeAttack", this); // Let attack finish before close range attack is executed.
		Owner.BlockCapabilities(n"OrbAttack", this); // Let attack finish before orb attack is executed.

		AnimComp.RequestFeature(FeatureTagIslandSecurityMech::SwingAttack, EBasicBehaviourPriority::Medium, this, Settings.MeleeAttackDuration);
		UIslandShieldotronEffectHandler::Trigger_OnMeleeAttackStart(Owner);

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
		Cooldown.Set(Settings.MeleeAttackCooldown);
		ProximityTimer = 0;
		DeactivateBehaviour(); // Ensures anim instance has a tick to update current tag.
		Owner.UnblockCapabilities(n"MortarAttack", this);
		Owner.UnblockCapabilities(n"CloseRangeAttack", this);
		Owner.UnblockCapabilities(n"OrbAttack", this);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!HasControl())
			return;

		if (((Owner.ActorLocation.IsWithinDist(Game::Mio.ActorLocation, Settings.MeleeAttackActivationRange) && Math::Abs(Owner.ActorLocation.Z - Game::Mio.ActorLocation.Z) < 100)	&& TargetComp.IsValidTarget(Game::Mio) )
			|| ( (Owner.ActorLocation.IsWithinDist(Game::Zoe.ActorLocation, Settings.MeleeAttackActivationRange) && Math::Abs(Owner.ActorLocation.Z - Game::Zoe.ActorLocation.Z) < 100) && TargetComp.IsValidTarget(Game::Zoe) )
			)
			ProximityTimer += DeltaTime;
		else
			ProximityTimer = 0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Telegraph duration, rotate towards player
		if (ActiveDuration < Settings.MeleeAttackDuration * 0.15)//TelegraphDuration + AnticipationDuration)
		{
			DestinationComp.RotateTowards(TargetPlayer);
		}
		// Attack phase duration, lock rotation
		else if (ActiveDuration < Settings.MeleeAttackDuration * 0.7) //TelegraphDuration + AnticipationDuration + AttackDuration)
		{
			// Check if player is within attack radius and deal damage, draw debug sphere
			FVector HitSphereLocation = Cast<AHazeCharacter>(Owner).Mesh.GetSocketTransform(n"RightForeArm").GetLocation(); // Only one of the arms for now
			float HitSphereRadius = Settings.MeleeAttackHitSphereRadius;
			
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
				Player.DealTypedDamage(Owner, Settings.MeleeAttackDamage, EDamageEffectType::ObjectSmall, EDeathEffectType::ObjectSmall);
				UIslandShieldotronEffectHandler::Trigger_OnMeleeAttackHit(Owner);

				float KnockdownDistance = Settings.MeleeAttackKnockdownDistance;
				float KnockdownDuration = Settings.MeleeAttackKnockdownDuration;;
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
				Debug::DrawDebugSphere(HitSphereLocation, HitSphereRadius, LineColor = FLinearColor::Green, Duration = 0.0);
#endif
		}		
		// Recovery duration, rotate towards again
		else if (ActiveDuration < Settings.MeleeAttackDuration)//TelegraphDuration + AttackDuration + RecoveryDuration)
		{
			DestinationComp.RotateTowards(TargetPlayer);
		}		
	}
}