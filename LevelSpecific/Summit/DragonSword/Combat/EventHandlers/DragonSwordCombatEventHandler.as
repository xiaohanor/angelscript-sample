struct FDragonSwordCombatStartRushEventData
{
	UPROPERTY()
	FVector StartLocation;
	UPROPERTY()
	FVector EndLocation;
	UPROPERTY()
	float TimeForAnimationToHit;
}

struct FDragonSwordCombatStartChargedRushEventData
{
	UPROPERTY()
	bool bIsGrounded;
	UPROPERTY()
	FVector StartLocation;
	UPROPERTY()
	FVector EndLocation;
}

struct FDragonSwordCombatStartAttackAnimationEventData
{
	UPROPERTY()
	int AttackIndex;
	UPROPERTY()
	EDragonSwordAttackMovementType MovementType;
	UPROPERTY()
	EDragonSwordCombatAttackDataHitType HitType;
	UPROPERTY()
	float AnimationDuration;
}

UCLASS(Abstract)
class UDragonSwordCombatEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(NotEditable, BlueprintReadOnly)
	ADragonSword DragonSword;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonSword = Cast<ADragonSword>(Owner);
		check(DragonSword != nullptr);
		
		Player = Game::Mio;
	}

	UFUNCTION(BlueprintPure)
	UDragonSwordCombatUserComponent GetCombatComp() const property
	{
		return UDragonSwordCombatUserComponent::Get(Player);
	}

	// Called when the player starts rush attacking towards an enemy
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartRush(FDragonSwordCombatStartRushEventData EventData) { }

	// Called when the player stops rush attacking
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopRush() { }

	// Called when the player starts attacking, only for the first attack
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartAttackSequence() { }

	// Called when a new attack animation is started
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartAttackAnimation(FDragonSwordCombatStartAttackAnimationEventData EventData) {}
	
	// Called when the player stops attacking.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopAttackSequence() { }

	// Called when the player enters the hit window where damage can be dealt
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartHitWindow() { }

	// Called when the player exits the hit window where damage can be dealt
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopHitWindow() { }

	// Called when an enemy is damaged
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitEnemy(FDragonSwordHitData HitData) {}
}