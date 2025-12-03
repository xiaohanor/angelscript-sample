struct FGravityBladeCombatStartRushEventData
{
	UPROPERTY()
	FVector StartLocation;
	UPROPERTY()
	FVector EndLocation;
	UPROPERTY()
	float TimeForAnimationToHit;
}

struct FGravityBladeCombatStartChargedRushEventData
{
	UPROPERTY()
	bool bIsGrounded;
	UPROPERTY()
	FVector StartLocation;
	UPROPERTY()
	FVector EndLocation;
}

struct FGravityBladeCombatStartAttackAnimationEventData
{
	UPROPERTY()
	int AttackIndex;
	UPROPERTY()
	EGravityBladeAttackMovementType MovementType;
	UPROPERTY()
	bool bIsSpin;
	UPROPERTY()
	float AnimationDuration;
}

struct FGravityBladeKillData
{
	UPROPERTY(BlueprintReadOnly)
	AHazeActor Victim;

	FGravityBladeKillData(AHazeActor _Victim)
	{
		Victim = _Victim;
	}
}

UCLASS(Abstract)
class UGravityBladeCombatEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(NotEditable, BlueprintReadOnly)
	AGravityBladeActor GravityBlade;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBlade = Cast<AGravityBladeActor>(Owner);
		check(GravityBlade != nullptr);
		
		Player = Game::Mio;
	}

	UFUNCTION(BlueprintPure)
	UGravityBladeCombatUserComponent GetCombatComp() const property
	{
		return UGravityBladeCombatUserComponent::Get(Player);
	}

	// Called when the player starts rush attacking towards an enemy
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartRush(FGravityBladeCombatStartRushEventData EventData) { }

	// Called when the player stops rush attacking
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopRush() { }

	// Called when the player starts attacking, only for the first attack
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartAttackSequence() { }

	// Called when a new attack animation is started
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartAttackAnimation(FGravityBladeCombatStartAttackAnimationEventData EventData) {}
	
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
	void OnHitEnemy(FGravityBladeHitData HitData) {}

	// Called when an enemy has been dealt a mortal blow by gravity blade
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartedKillingEnemy(FGravityBladeKillData Data) {}

	// Called when we have started a glory kill against someone
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartedGloryKilling(FGravityBladeKillData Data) {}
}