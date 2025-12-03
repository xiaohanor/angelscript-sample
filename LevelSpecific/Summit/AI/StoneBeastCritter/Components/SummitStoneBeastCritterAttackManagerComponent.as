class USummitStoneBeastCritterAttackManagerComponent : UActorComponent
{
	// Will tell an individual attacker whether enough critters are in range to start knockdown attack
	private TSet<AHazeActor> AttackersInRange;

	// Will tell an individual attacker whether other critters have started telegraphing the attack.
	private TSet<AHazeActor> AttackersActive;

	// Will tell the pinned knockdown capability that player is still pinned down by at least one attacker.
	private TSet<AHazeActor> AttackersEngaged;

	private float AttackStartedTime;

	private USummitStoneBeastCritterAttackManagerComponent OtherAttackManager;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AHazePlayerCharacter OtherPlayer = Cast<AHazePlayerCharacter>(Owner) == Game::Mio ? Game::Zoe : Game::Mio;
		OtherAttackManager = SummitStoneBeastCritter::GetManager(OtherPlayer);
	}

	void AddInAttackRange(AHazeActor Attacker)
	{
		AttackersInRange.Add(Attacker);
	}

	void RemoveInAttackRange(AHazeActor Attacker)
	{
		AttackersInRange.Remove(Attacker);
	}

	bool IsOtherPlayerBeingAttacked()
	{
		if (OtherAttackManager == nullptr)
			return false;
		
		if (!OtherAttackManager.HasActiveAttackers())
			return false;

		return true;
	}

	bool CanAttack(AHazeActor Attacker) const
	{
		// Is attacker in range?
		if (!AttackersInRange.Contains(Attacker))
			return false;
		
		// Fellow critters are telegraphing, clear to engage
		if (AttackersActive.Num() >= 3) // TODO: setting for minimum number of attackers
			return true;
		
		// If attack has not started, we need at least a number of attackers to engage.
		if (AttackersInRange.Num() < 3) // TODO: setting for minimum number of attackers
			return false;

		return true;
	}


	void AddAttackerEngaged(AHazeActor Attacker)
	{
		AttackersEngaged.Add(Attacker);
	}

	void RemoveAttackerEngaged(AHazeActor Attacker)
	{
		AttackersEngaged.Remove(Attacker);
	}


	void AddAttackerActive(AHazeActor Attacker)
	{
		AttackersActive.Add(Attacker);		
	}

	void RemoveAttackerActive(AHazeActor Attacker)
	{
		AttackersActive.Remove(Attacker);
	}


	void SaveStartedAttackTime()
	{
		AttackStartedTime = Time::GameTimeSeconds;
	}

	float GetStartedAttackTime() const
	{
		return AttackStartedTime;
	}
	

	bool HasActiveAttackers() const
	{
		return !AttackersActive.IsEmpty();
	}

	bool HasAttackHit() const
	{
		return !AttackersEngaged.IsEmpty();
	}


	void Reset()
	{
		AttackersInRange.Empty();
		AttackersActive.Empty();
		AttackersEngaged.Empty();
	}

	// Attacker changed target or died.
	void RemoveFromManager(AHazeActor Attacker)
	{
		RemoveInAttackRange(Attacker);
		RemoveAttackerActive(Attacker);
		RemoveAttackerEngaged(Attacker);
	}
};

class USummitStoneBeastCritterAttackManagerEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStartFlyingSpawn(FOnStoneCritterSpawnParams Params) {}
}