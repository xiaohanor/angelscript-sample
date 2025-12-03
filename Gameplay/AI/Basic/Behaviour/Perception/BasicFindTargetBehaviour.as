class UBasicFindTargetBehaviour : UBasicBehaviour
{
	// Targeting behaviour need only run on control side, results are replicated
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Perception);

	UBasicAIHealthComponent HealthComp;

	float RespondToAlarmDelay;
	AHazeActor LastAttacker;
	float LastAttackedTime = -BIG_NUMBER;

	TArray<AHazeActor> RememberedTargets;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		HealthComp.OnTakeDamage.AddUFunction(this, n"OnTakeDamage");
		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"Reset");
	}

	UFUNCTION()
	private void Reset()
	{	
		LastAttacker = nullptr;
		LastAttackedTime = -BIG_NUMBER;
		RememberedTargets.Empty();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		RespondToAlarmDelay = Math::RandRange(BasicSettings.FindTargetRespondToAlarmDelay, BasicSettings.FindTargetRespondToAlarmDelay * 1.5);
	
		for (int i = RememberedTargets.Num() - 1; i >= 0; i--)
		{
			if (!TargetComp.IsValidTarget(RememberedTargets[i]))
				RememberedTargets.RemoveAtSwap(i);
		}
	}

	UFUNCTION()
	private void OnTakeDamage(AHazeActor ActorTakingDamage, AHazeActor Attacker, float Damage, EDamageType Type)
	{
		// The dead do not care
		if (HealthComp.IsDead())
			return;

		// Take note of attackers even when not active, so we can remember them later
		// Ignore when blocked though
		if (IsBlocked())
			return;

		// We forgive any non-potential targets for attacking us.
		if (!TargetComp.IsPotentialTarget(Attacker))
			return;

		// Within range?
		if (!Attacker.ActorCenterLocation.IsWithinDist(Owner.FocusLocation, BasicSettings.DetectAttackerRange))
			return;

		LastAttacker = Attacker;
		LastAttackedTime = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Use specific aggro target if any
		AHazeActor Target = TargetComp.AggroTarget;

		// Check if we've detected an attacker
		if ((Target == nullptr) && (LastAttacker != nullptr))
		{
			if (Time::GetGameTimeSince(LastAttackedTime) < BasicSettings.FindTargetRememberAttackerDuration)
				Target = LastAttacker;
			LastAttacker = nullptr;
		}

		// Can we otherwise perceive a target?
		if (Target == nullptr)
	 		Target = TargetComp.FindClosestTarget(BasicSettings.AwarenessRange);
		
		// Have alarm been raised for any targets?
		if (Target == nullptr)
			Target = TargetComp.FindAlarmTarget(BasicSettings.RespondToAlarmRange, RespondToAlarmDelay, BasicSettings.FindTargetRememberAlarmDuration);			

		if (BasicSettings.bAlwaysRememberTarget && Target == nullptr)
		{
			float ClosestDistSqr = BIG_NUMBER;

			for (auto RememberedTarget : RememberedTargets)
			{
				float DistSqr = Owner.FocusLocation.DistSquared(RememberedTarget.FocusLocation);
				if (DistSqr < ClosestDistSqr)
				{
					ClosestDistSqr = DistSqr;
					Target = RememberedTarget;
				}
			}
		}

		if (Target != nullptr)
		{
			RememberedTargets.AddUnique(Target);

			TargetComp.SetTarget(Target);
			return;
		}
	}
}
