class UEnforcerChargeMeleeAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	default CapabilityTags.Add(n"Attack");

	USkylineEnforcerSettings Settings;
	UBasicAIHealthComponent HealthComp;
	UEnforcerChargeMeleeComponent MeleeComp;

	float TelegraphDuration = 0.4;
	float AnticipationDuration = 0.1;
	float AttackDuration = 0.2;
	float RecoveryDuration = 0.9;

	TSet<AHazePlayerCharacter> HasHitSet;
	bool bStartAttack;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USkylineEnforcerSettings::GetSettings(Owner);		
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		MeleeComp = UEnforcerChargeMeleeComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > TelegraphDuration + AnticipationDuration + AttackDuration + RecoveryDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		if(!Owner.ActorLocation.IsWithinDist(MeleeComp.TargetPlayer.ActorLocation, 200))
			DeactivateBehaviour();

		FBasicAIAnimationActionDurations AttackDurations;
		AttackDurations.Telegraph = TelegraphDuration;
		AttackDurations.Anticipation = AnticipationDuration;
		AttackDurations.Action = AttackDuration;
		AttackDurations.Recovery = RecoveryDuration;
		AnimComp.RequestAction(LocomotionFeatureAISkylineTags::EnforcerMeleeAttack, EBasicBehaviourPriority::Medium, this, AttackDurations);	

		HasHitSet.Reset();

		UEnforcerEffectHandler::Trigger_OnChargeMeleeAttackStart(Owner);	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(1.0);
		AnimComp.ClearFeature(this);

		if(HasHitSet.IsEmpty())
			UEnforcerEffectHandler::Trigger_OnChargeMeleeAttackHadMiss(Owner);
		else
			UEnforcerEffectHandler::Trigger_OnChargeMeleeAttackHadHit(Owner);

		UEnforcerEffectHandler::Trigger_OnChargeMeleeAttackStop(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Telegraph duration, rotate towards player
		if (ActiveDuration < TelegraphDuration + AnticipationDuration)
		{
			DestinationComp.RotateTowards(MeleeComp.TargetPlayer);
		}
		// Attack phase duration, lock rotation
		else if (ActiveDuration < TelegraphDuration + AnticipationDuration + AttackDuration)
		{
			// Check if player is within attack radius and deal damage, draw debug sphere
			FVector HitSphereLocation = Cast<AHazeCharacter>(Owner).Mesh.GetSocketTransform(n"RightHand").GetLocation();// Owner.ActorLocation + Owner.ActorForwardVector * 100; // Arbitrary offset for testing. Can try replacing with bone's world location for sweeping check.
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
				UEnforcerEffectHandler::Trigger_OnChargeMeleeAttackImpact(Owner);
				Player.DamagePlayerHealth(Settings.ChargeMeleeAttackDamage, DamageEffect = MeleeComp.DamageEffect, DeathEffect = MeleeComp.DeathEffect);

				float StumbleDistance = Settings.ChargeMeleeAttackStumbleDistance;
				float StumbleDuration = Settings.ChargeMeleeAttackStumbleDuration;;
				if (StumbleDistance > 0.0)
				{
					FStumble Stumble;
					Stumble.Move = Owner.ActorForwardVector * StumbleDistance;
					Stumble.Duration = StumbleDuration;
					Player.ApplyStumble(Stumble);
				}
			}

			DestinationComp.MoveTowards(Owner.ActorLocation + Owner.ActorForwardVector * 500, 100);

#if EDITOR
			// Draw hit sphere
			//Owner.bHazeEditorOnlyDebugBool = true;
			if (Owner.bHazeEditorOnlyDebugBool) 
				Debug::DrawDebugSphere(HitSphereLocation, HitSphereRadius, LineColor = FLinearColor::Green, Duration = 0.0);
#endif
		}
		
		// Recovery duration, rotate towards again
		else if (ActiveDuration < TelegraphDuration + AttackDuration + RecoveryDuration)
		{
			DestinationComp.RotateTowards(MeleeComp.TargetPlayer);
		}		
	}
}