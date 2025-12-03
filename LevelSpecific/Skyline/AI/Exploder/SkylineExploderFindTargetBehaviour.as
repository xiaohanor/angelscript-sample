// TODO: Use gentleman queuing so they are not all chasing at the same time
// TODO: Setup timer to not check for path every tick

class USkylineExploderFindTargetBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Perception);

	UBasicAIHealthComponent HealthComp;

	float RespondToAlarmDelay;
	AHazeActor LastAttacker;
	float LastAttackedTime = -BIG_NUMBER;

	TArray<AHazeActor> RememberedTargets;

	const float ActivationWaitDuration = 0.5;
	float LastActivationTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		HealthComp.OnTakeDamage.AddUFunction(this, n"OnTakeDamage");
		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"Reset");

		// Add some random time to have the find checks not happen all at the same frame
		LastActivationTime = Time::GetGameTimeSeconds() + Math::RandRange(0.0, ActivationWaitDuration);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(Time::GetGameTimeSince(LastActivationTime) < ActivationWaitDuration)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		return true;
	}

	UFUNCTION()
	private void Reset()
	{	
		LastAttacker = nullptr;
		LastAttackedTime = -BIG_NUMBER;
		RememberedTargets.Empty();
		TargetComp.SetTarget(nullptr);
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
	void OnActivated()
	{
		Super::OnActivated();
		LastActivationTime = Time::GetGameTimeSeconds();

		if(TargetComp.Target != nullptr)
		{
			if(!HasPath(TargetComp.Target))
				TargetComp.SetTarget(nullptr);

			return;
		}

		AHazeActor FinalTarget = nullptr;
		TArray<AHazeActor> Targets;
		TArray<AHazeActor> RangeTargets;
		TargetComp.FindAllTargets(BIG_NUMBER, Targets);
		TargetComp.FindAllTargets(BasicSettings.AwarenessRange, RangeTargets);
		Targets.Shuffle();

		for(AHazeActor Target: Targets)
		{
			// Use specific aggro target if any
			if(Target == TargetComp.AggroTarget)
				FinalTarget = Target;

			// Check if we've detected an attacker
			if ((FinalTarget == nullptr) && (LastAttacker == Target))
			{
				if (Time::GetGameTimeSince(LastAttackedTime) < BasicSettings.FindTargetRememberAttackerDuration)
					FinalTarget = LastAttacker;
				LastAttacker = nullptr;
			}

			// Can we otherwise perceive a target?
			if (FinalTarget == nullptr && RangeTargets.Contains(Target))
	 			FinalTarget = Target;
			
			// Have alarm been raised for any targets?
			if (FinalTarget == nullptr)
			{
				RespondToAlarmDelay = Math::RandRange(BasicSettings.FindTargetRespondToAlarmDelay, BasicSettings.FindTargetRespondToAlarmDelay * 1.5);
				if(Target == TargetComp.FindAlarmTarget(BasicSettings.RespondToAlarmRange, RespondToAlarmDelay, BasicSettings.FindTargetRememberAlarmDuration))
					FinalTarget = Target;
			}			

			if (BasicSettings.bAlwaysRememberTarget && FinalTarget == nullptr)
			{
				float ClosestDistSqr = BIG_NUMBER;

				for (int i = RememberedTargets.Num() - 1; i >= 0; i--)
				{
					if (!TargetComp.IsValidTarget(RememberedTargets[i]))
						RememberedTargets.RemoveAtSwap(i);
				}

				for (auto RememberedTarget : RememberedTargets)
				{
					float DistSqr = Owner.FocusLocation.DistSquared(RememberedTarget.FocusLocation);
					if (DistSqr < ClosestDistSqr)
					{
						ClosestDistSqr = DistSqr;
						FinalTarget = RememberedTarget;
					}
				}
			}

			if (FinalTarget != nullptr && !HasPath(FinalTarget))
				FinalTarget = nullptr;
			
			if(FinalTarget != nullptr)
				break;
		}

		if (FinalTarget != nullptr)
		{
			RememberedTargets.AddUnique(FinalTarget);
			TargetComp.SetTarget(FinalTarget);
			return;
		}
	}

	private bool HasPath(AHazeActor Target)
	{
		FVector StartLocation;
		if(!Pathfinding::FindNavmeshLocation(Owner.ActorLocation, 100.0, 400.0, StartLocation))
			return false;

		FVector EndLocation;
		if(!Pathfinding::FindNavmeshLocation(Target.ActorLocation, 100.0, 400.0, EndLocation))
			return false;

		return Pathfinding::HasPath(StartLocation, EndLocation);
	}
}
