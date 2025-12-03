event void FBasicAIChangeTarget(AHazeActor NewTarget, AHazeActor OldTarget);

class UBasicAITargetingComponent : UActorComponent
{
	FBasicAIChangeTarget OnChangeTarget;

	// These players will be considered potential targets
	UPROPERTY()
	EHazeSelectPlayer PlayerTargets = EHazeSelectPlayer::Both;

	// Any non-players that can be treated as targets
	UPROPERTY()
	TArray<AHazeActor> PotentialTargets;

	private TArray<AHazeActor> AllPotentialTargets;
	
	private AHazeActor HazeOwner;
	private AHazeActor CurrentTarget;
	private AHazeActor CurrentAggroTarget;
	private AHazeActor AlarmTarget;
	private float AlarmTime;
	private UGentlemanComponent CurrentGentlemanComp;
	private UBasicAIPerceptionComponent PerceptionComp;

	private UBasicAISettings Settings;
	private float SetTargetTime = -BIG_NUMBER;
	private bool bHasVisibleTarget = false;
	private float TargetVisibleCheckTime = 0.0;
	private bool bHasGeometryVisibleTarget = false;
	private float TargetGeometryVisibleCheckTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(Owner);

		AllPotentialTargets = PotentialTargets;
		const TArray<AHazePlayerCharacter>& Players = Game::GetPlayersSelectedBy(PlayerTargets);
		for (AHazePlayerCharacter Player : Players)
		{
			AllPotentialTargets.AddUnique(Player);
		}

		PerceptionComp = UBasicAIPerceptionComponent::GetOrCreate(Owner);

		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		if(RespawnComp != nullptr)
		{
			RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
			RespawnComp.OnUnspawn.AddUFunction(this, n"OnUnspawn");
		}

		Settings = UBasicAISettings::GetSettings(HazeOwner);

		TargetVisibleCheckTime = Time::GameTimeSeconds + Math::RandRange(0.0, Settings.FindTargetLineOfSightInterval);
	}

	void GetPotentialTargets(TArray<AHazeActor>& Targets) const
	{
		Targets.Append(AllPotentialTargets);
	}

	UFUNCTION()
	private void OnUnspawn(AHazeActor RespawnableActor)
	{
		// This is networked outside
		SetTargetLocal(nullptr);
	}

	
	UFUNCTION(NotBlueprintCallable)
	void OnRespawn()
	{
		// This is networked outside
		SetTargetLocal(nullptr);
	}


	UFUNCTION()
	void SetAggroTarget(AHazeActor NewAggroTarget) property
	{
		this.CurrentAggroTarget = NewAggroTarget;
	}

	UFUNCTION()
	AHazeActor GetAggroTarget() property
	{
		return CurrentAggroTarget;
	}

	UFUNCTION()
	void RaiseAlarm(AHazeActor RaisedAlarmTarget)
	{
		if (!IsValidTarget(RaisedAlarmTarget))
			return;

		if ((this.AlarmTarget != nullptr) && (this.AlarmTarget != RaisedAlarmTarget))
		{
			// Should we ignore new alarm target in favor of previous one?
			FVector FocusLoc = HazeOwner.FocusLocation;
			if (FocusLoc.DistSquared(this.AlarmTarget.ActorCenterLocation) < FocusLoc.DistSquared(RaisedAlarmTarget.ActorCenterLocation))
				return; 
		}

		AlarmTime = Time::GameTimeSeconds;
		this.AlarmTarget = RaisedAlarmTarget;
	}

	void SetTargetLocal(AHazeActor NewTarget)
	{
		if (NewTarget == CurrentTarget)
			return;

		AHazeActor OldTarget = CurrentTarget; 
		CurrentTarget = NewTarget;
		CurrentAggroTarget = nullptr;
		AlarmTarget = nullptr;
		bHasVisibleTarget = false;
		SetTargetTime = (NewTarget == nullptr) ? -BIG_NUMBER : Time::GameTimeSeconds;

		if (CurrentGentlemanComp != nullptr)
		{
			CurrentGentlemanComp.ClearClaimantFromAllSemaphores(HazeOwner);
			CurrentGentlemanComp.RemoveOpponent(HazeOwner);
		}

		// Update gentleman fighting comp. 
		if (NewTarget == nullptr)
		{
			CurrentGentlemanComp = nullptr;
		}
		else
		{
			CurrentGentlemanComp = UGentlemanComponent::GetOrCreate(NewTarget);
			CurrentGentlemanComp.AddOpponent(HazeOwner);
		}

		OnChangeTarget.Broadcast(NewTarget, OldTarget);
	}

    AHazeActor GetTarget() const property
    {
        return CurrentTarget;
    }

    void SetTarget(AHazeActor NewTarget) property
    {
		if (HasControl() && (NewTarget != CurrentTarget))
			CrumbSetTarget(NewTarget);
    }

	float GetDistanceToTarget() const property
	{
		if (CurrentTarget == nullptr)
			return 0.0;
		
		return (Owner.ActorLocation - CurrentTarget.ActorLocation).Size();
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
    private void CrumbSetTarget(AHazeActor NewTarget)
	{
		SetTargetLocal(NewTarget);
	}

	bool IsValidTarget(AHazeActor CheckTarget) const
	{
		if (CheckTarget == nullptr)
			return false;
		if (CheckTarget.IsActorDisabled())
			return false;

		UGentlemanComponent GentlemanComp = UGentlemanComponent::Get(CheckTarget);
		if ((GentlemanComp != nullptr) && !GentlemanComp.IsValidTarget())
			return false;

		AHazePlayerCharacter PlayerTarget = Cast<AHazePlayerCharacter>(CheckTarget);
		if (PlayerTarget != nullptr)
		{
			bool Alive = !UPlayerHealthComponent::Get(PlayerTarget).bIsDead;
			return Alive;
		}

		UBasicAIHealthComponent HealthComp = UBasicAIHealthComponent::Get(CheckTarget);
		if (HealthComp != nullptr)
			return HealthComp.IsAlive();

		return true;
	}

	bool HasValidTarget() const
	{
		return IsValidTarget(CurrentTarget);
	}

	bool HasVisibleTarget(FVector OwnerOffset = FVector::ZeroVector, FVector TargetOffset = FVector::ZeroVector) 
	{
		if (!HasValidTarget())
			return false;			

		if (Time::GameTimeSeconds > TargetVisibleCheckTime)
		{
			bHasVisibleTarget = PerceptionComp.Sight.VisibilityExists(HazeOwner, Target, OwnerOffset, TargetOffset);
			TargetVisibleCheckTime = Time::GameTimeSeconds + Settings.FindTargetLineOfSightInterval;
		}
		return bHasVisibleTarget;
	}

	bool HasGeometryVisibleTarget(FVector OwnerOffset = FVector::ZeroVector, FVector TargetOffset = FVector::ZeroVector)
	{
		if (!HasValidTarget())
			return false;

		if (Time::GameTimeSeconds > TargetGeometryVisibleCheckTime)
		{
			bHasGeometryVisibleTarget = PerceptionComp.Sight.VisibilityExists(HazeOwner, Target, OwnerOffset, TargetOffset, CollisionChannel = ECollisionChannel::WorldGeometry);
			TargetGeometryVisibleCheckTime = Time::GameTimeSeconds + Settings.FindTargetLineOfSightInterval;
		}
		return bHasGeometryVisibleTarget;
	}

	UGentlemanComponent GetGentlemanComponent() property
	{
		return CurrentGentlemanComp;
	}

	AHazeActor FindClosestTarget(float Range)
	{
		// Simple for now, expand with actual senses as needed
		AHazeActor BestTarget = nullptr;
		float BestDistSqr = Math::Square(Range);
		FVector SenseLoc = 	HazeOwner.FocusLocation;	
		for (AHazeActor PotentialTarget : AllPotentialTargets)
		{
			if (!IsValidTarget(PotentialTarget))
				continue;

			float DistSqr = SenseLoc.DistSquared(PotentialTarget.FocusLocation);
			if (DistSqr < BestDistSqr)
			{
				BestDistSqr = DistSqr;
				BestTarget = PotentialTarget;
			}
		}
		return BestTarget;
	}

	void FindAllTargets(float Range, TArray<AHazeActor>& OutTargets)
	{
		FVector SenseLoc = 	HazeOwner.FocusLocation;

		for (AHazeActor PotentialTarget : AllPotentialTargets)
		{
			if (!IsValidTarget(PotentialTarget))
				continue;
			if (SenseLoc.IsWithinDist(PotentialTarget.FocusLocation, Range))	
				OutTargets.AddUnique(PotentialTarget);
		}
	}

	AHazeActor FindAlarmTarget(float Range, float MinRespondTime, float MaxRespondTime)
	{
		if (!IsValidTarget(AlarmTarget))
			return nullptr;

		if (Time::GetGameTimeSince(AlarmTime) < MinRespondTime)
			return nullptr;

		if (Time::GetGameTimeSince(AlarmTime) > MaxRespondTime)
			return nullptr;

		if (!HazeOwner.FocusLocation.IsWithinDist(AlarmTarget.ActorCenterLocation, Range))
			return nullptr;

		return AlarmTarget;
	}

	bool IsPotentialTarget(AHazeActor Actor)
	{
		return AllPotentialTargets.Contains(Actor);
	}

	float GetSameTargetDuration()
	{
		if (SetTargetTime == -BIG_NUMBER)
			return 0.0;

		return (Time::GameTimeSeconds - SetTargetTime);
	}

	void SetPotentialTargets(TArray<AHazeActor> InPotentialTargets)
	{
		PotentialTargets = InPotentialTargets;
		AllPotentialTargets = PotentialTargets;
	}

	bool IsChargeHit(AHazeActor ChargeTarget, float Radius, float PredictionTime = 0.1, float MinSpeed = 100.0)
	{
		UBasicAIHealthComponent HealthComp = UBasicAIHealthComponent::Get(Owner);
		return Behaviour::IsChargeHit(HazeOwner, ChargeTarget, Radius, HealthComp.IsAlive(), PredictionTime, MinSpeed);
	}
}
