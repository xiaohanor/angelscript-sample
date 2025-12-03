//Try to balance number of attackers per player
class USkylineGeckoFindTarget : UBasicBehaviour
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
		AHazeActor Target = GetBestTarget(); 
		LastAttacker = nullptr;

		if (Target != nullptr)
		{
			RememberedTargets.AddUnique(Target);

			TargetComp.SetTarget(Target);
			return;
		}
	}

	AHazeActor GetBestTarget()
	{
		AHazeActor Target;

		if (TargetComp.AggroTarget != nullptr)
			return TargetComp.AggroTarget;

		TArray<AHazeActor> KnownTargets;
		if (BasicSettings.bAlwaysRememberTarget)
			KnownTargets.Append(RememberedTargets);

		// Check if we've detected an attacker
		if (LastAttacker != nullptr)
		{
			if (Time::GetGameTimeSince(LastAttackedTime) < BasicSettings.FindTargetRememberAttackerDuration)
				KnownTargets.AddUnique(LastAttacker);
		}

		//Add all perceived targets
		TargetComp.FindAllTargets(BasicSettings.AwarenessRange, KnownTargets);

		// Have alarm been raised for any targets?
		AHazeActor AlarmedTarget = TargetComp.FindAlarmTarget(BasicSettings.RespondToAlarmRange, RespondToAlarmDelay, BasicSettings.FindTargetRememberAlarmDuration);			
		if (AlarmedTarget != nullptr)
			KnownTargets.AddUnique(AlarmedTarget);

		for (AHazeActor KnownTarget : KnownTargets)
		{
			auto GeckoArea = USkylineGeckoAreaPlayerComponent::GetOrCreate(KnownTarget);
			if(GeckoArea.SameArea(Owner))
				return KnownTarget;
		}

		int LeastNumAttackers = 1000000;
		TArray<AHazeActor> LeastAttackedTargets;

		for (AHazeActor KnownTarget : KnownTargets)
		{
			UGentlemanComponent GentleComp = UGentlemanComponent::GetOrCreate(KnownTarget);
			int NumOpponents = GentleComp.GetNumOtherOpponents(Owner);
			if (NumOpponents < LeastNumAttackers)
			{
				LeastNumAttackers = NumOpponents;
				LeastAttackedTargets.Empty();
				LeastAttackedTargets.Add(KnownTarget);
			}
			else if (NumOpponents == LeastNumAttackers)
			{
				LeastAttackedTargets.Add(KnownTarget);
			}
		}

		if (LeastAttackedTargets.Num() == 1)
			return LeastAttackedTargets[0];

		if (LeastAttackedTargets.Contains(LastAttacker))
			return LastAttacker;

		AHazeActor ClosestTarget = Target;
		FVector SenseLoc = 	Owner.FocusLocation;	
		float BestDistSqr = (Target == nullptr) ? BIG_NUMBER : SenseLoc.DistSquared(Target.FocusLocation) * 0.75 * 0.75;
		for (AHazeActor LeastAttackedTarget : LeastAttackedTargets)
		{
			float DistSqr = SenseLoc.DistSquared(LeastAttackedTarget.FocusLocation);
			if (DistSqr < BestDistSqr)
			{
				BestDistSqr = DistSqr;
				ClosestTarget = LeastAttackedTarget;
			}
		}
		return ClosestTarget;
	}	
}
