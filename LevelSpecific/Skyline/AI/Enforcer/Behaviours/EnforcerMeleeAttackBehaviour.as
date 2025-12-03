class UEnforcerMeleeAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	USkylineEnforcerSettings Settings;

	float TelegraphDuration = 0.6;
	float AnticipationDuration = 0.4;
	float AttackDuration = 0.3;
	float RecoveryDuration = 1.0;

	AHazePlayerCharacter TargetPlayer;

	TSet<AHazePlayerCharacter> HasHitSet;
	float ProximityTimer = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USkylineEnforcerSettings::GetSettings(Owner);		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;

		if (!TargetComp.HasValidTarget())
			return false;

		if (ProximityTimer < Settings.MeleeAttackActivationTimer)
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

		FBasicAIAnimationActionDurations AttackDurations;
		AttackDurations.Telegraph = TelegraphDuration;
		AttackDurations.Anticipation = AnticipationDuration;
		AttackDurations.Action = AttackDuration; 
		AttackDurations.Recovery = RecoveryDuration;
		AnimComp.RequestAction(LocomotionFeatureAISkylineTags::EnforcerMeleeAttack, EBasicBehaviourPriority::Medium, this, AttackDurations);	

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
		//Cooldown.Set(5.0);
		ProximityTimer = 0;
		AnimComp.ClearFeature(this);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!HasControl())
			return;

		if (!Owner.ActorLocation.IsWithinDist(Game::Mio.ActorLocation, Settings.MeleeAttackActivationRange) &&
			!Owner.ActorLocation.IsWithinDist(Game::Zoe.ActorLocation, Settings.MeleeAttackActivationRange))
			ProximityTimer = 0;
		else
			ProximityTimer += DeltaTime;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Telegraph duration, rotate towards player
		if (ActiveDuration < TelegraphDuration + AnticipationDuration)
		{
			DestinationComp.RotateTowards(TargetPlayer);
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
				Player.DamagePlayerHealth(Settings.MeleeAttackDamage);					 

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
		else if (ActiveDuration < TelegraphDuration + AttackDuration + RecoveryDuration)
		{
			DestinationComp.RotateTowards(TargetPlayer);
		}		
	}
}