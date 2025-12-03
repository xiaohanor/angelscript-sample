class UEnforcerAreaAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	USkylineEnforcerSettings Settings;

	AHazePlayerCharacter TargetPlayer;

	TSet<AHazePlayerCharacter> HasHitSet;
	float ProximityTimer = 0;
	float Duration = 1;
	bool bDamageStarted;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USkylineEnforcerSettings::GetSettings(Owner);		
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!HasControl())
			return;

		if (!Owner.ActorLocation.IsWithinDist(Game::Mio.ActorLocation, Settings.AreaAttackActivationRange) &&
			!Owner.ActorLocation.IsWithinDist(Game::Zoe.ActorLocation, Settings.AreaAttackActivationRange))
			ProximityTimer = 0;
		else
			ProximityTimer += DeltaTime;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;

		if (!TargetComp.HasValidTarget())
			return false;

		if (ProximityTimer < Settings.AreaAttackActivationTimer)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;

		if (ActiveDuration > Duration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		FBasicAIAnimationActionDurations AttackDurations;
		AnimComp.RequestFeature(LocomotionFeatureAISkylineTags::EnforcerAreaAttack, EBasicBehaviourPriority::Medium, this, Duration);	

		// Nearest player serves as target for the attack
		if (Owner.ActorLocation.DistSquared(Game::Mio.ActorLocation) < Owner.ActorLocation.DistSquared(Game::Zoe.ActorLocation) )
			TargetPlayer = Game::Mio;
		else
			TargetPlayer = Game::Zoe;

		HasHitSet.Reset();
		bDamageStarted = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		ProximityTimer = 0;
		Cooldown.Set(4);
		AnimComp.ClearFeature(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Telegraph duration, rotate towards player
		if (ActiveDuration < 0.15)
		{
			DestinationComp.RotateTowards(TargetPlayer);
		}
		// Attack phase duration, lock rotation
		else if (ActiveDuration < 0.3)
		{
			if(!bDamageStarted)
			{
				bDamageStarted = true;
				UEnforcerEffectHandler::Trigger_OnAreaAttackImpact(Owner);
			}

			for(AHazePlayerCharacter Player : Game::Players)
			{
				if(Player.GetDistanceTo(Owner) > Settings.AreaAttackHitSphereRadius)
					continue;
				if (HasHitSet.Contains(Player))
					continue;

				HasHitSet.Add(Player);
				Player.DamagePlayerHealth(Settings.AreaAttackDamage);

				float KnockdownDistance = Settings.AreaAttackKnockdownDistance;
				if (KnockdownDistance > 0.0)
				{
					FStumble Stumble;
					Stumble.Move = (Player.ActorLocation - Owner.ActorLocation).ConstrainToPlane(Player.ActorUpVector).GetNormalizedWithFallback(-Player.ActorForwardVector) * KnockdownDistance;
					Stumble.Duration = Settings.AreaAttackKnockdownDuration;
					Player.ApplyStumble(Stumble);
				}
			}
		}
		// Recovery duration, rotate towards again
		else
		{
			DestinationComp.RotateTowards(TargetPlayer);
		}		
	}
}