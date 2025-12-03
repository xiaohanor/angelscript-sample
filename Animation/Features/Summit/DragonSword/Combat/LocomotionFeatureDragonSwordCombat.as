struct FLocomotionFeatureDragonSwordCombatAnimData
{
	UPROPERTY(Category = "DragonSwordCombat|Attacks")
	FDragonSwordAttackDefinition GroundAttacks;

	UPROPERTY(Category = "DragonSwordCombat|Attacks")
	FDragonSwordAttackDefinition AirAttacks;

	UPROPERTY(Category = "DragonSwordCombat|AirAttack")
	FHazePlaySequenceData AirAttackEnter;

	UPROPERTY(Category = "DragonSwordCombat|AirAttack")
	FHazePlaySequenceData AirAttackMh;

	UPROPERTY(Category = "DragonSwordCombat|AirAttack")
	FHazePlaySequenceData AirAttackExit;

	UPROPERTY(Category = "DragonSwordCombat|Attacks")
	FDragonSwordAttackDefinition DashAttacks;

	UPROPERTY(Category = "DragonSwordCombat|ChargeAttack")
	FHazePlaySequenceData ChargeAttackEnter;

	UPROPERTY(Category = "DragonSwordCombat|ChargeAttack")
	FHazePlaySequenceData ChargeAttackMh;

	UPROPERTY(Category = "DragonSwordCombat|ChargeAttack")
	FHazePlaySequenceData ChargeAttackExit;
}

class ULocomotionFeatureDragonSwordCombat : UHazeLocomotionFeatureBase
{
	default Tag = n"DragonSwordCombat";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureDragonSwordCombatAnimData AnimData;

	FDragonSwordAttackSequenceData GetSequenceFromAttackType(EDragonSwordCombatAttackType AttackType, int SequenceIndex) const
	{
		switch (AttackType)
		{
			case EDragonSwordCombatAttackType::Air:
				devCheck(SequenceIndex >= 0 && SequenceIndex < AnimData.AirAttacks.Sequences.Num(), f"Sequence index was {SequenceIndex} when trying to get air attack (Num: {AnimData.AirAttacks.Sequences.Num()})!");
				return AnimData.AirAttacks.Sequences[SequenceIndex];

			case EDragonSwordCombatAttackType::Dash:
			case EDragonSwordCombatAttackType::DashRush:
				devCheck(SequenceIndex >= 0 && SequenceIndex < AnimData.DashAttacks.Sequences.Num(), f"Sequence index was {SequenceIndex} when trying to get dash attack (Num: {AnimData.DashAttacks.Sequences.Num()})!");
				return AnimData.DashAttacks.Sequences[SequenceIndex];

			case EDragonSwordCombatAttackType::Charge:
				return AnimData.GroundAttacks.Sequences[0];
			case EDragonSwordCombatAttackType::Ground:
			case EDragonSwordCombatAttackType::GroundRush:
				devCheck(SequenceIndex >= 0 && SequenceIndex < AnimData.GroundAttacks.Sequences.Num(), f"Sequence index was {SequenceIndex} when trying to get ground attack (Num: {AnimData.GroundAttacks.Sequences.Num()})!");
				return AnimData.GroundAttacks.Sequences[SequenceIndex];

			default:
				break;
		}

		check(false);
		return FDragonSwordAttackSequenceData();
	}
}

struct FDragonSwordAttackDefinition
{
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Attack Data")
	bool bCanWrap = false;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Attack Data")
	bool bRandomizeSequenceIndex = false;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Attack Data")
	TArray<FDragonSwordAttackSequenceData> Sequences;
}

class UDragonSwordAttackData : UDataAsset
{
	UPROPERTY(EditDefaultsOnly, meta = (ShowOnlyInnerProperties))
	FHazePlaySequenceData Animation;

	// Total amount of units we move over the animation length, temporary until root motion can be retrieved.
	UPROPERTY(EditDefaultsOnly)
	float MovementLength = 150.0;

	UPROPERTY(EditDefaultsOnly)
	float TraceRange = 200;

	UPROPERTY(EditDefaultsOnly)
	EDragonSwordCombatAttackDataHitType HitType;

	UPROPERTY(EditDefaultsOnly)
	float AdditionalMovementDuration = 0.1;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ForceFeedbackEffect;
}

/**
 * Defines a type of attack sequence.
 */
struct FDragonSwordAttackSequenceData
{
	// Attack data for each attack in this sequence.
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Sequence")
	TArray<UDragonSwordAttackData> Attacks;

	UDragonSwordAttackData GetAnimationFromIndex(int Index) const
	{
		if (Attacks.Num() == 0)
		{
			return nullptr;
		}

		if (Index < 0 || Index >= Attacks.Num())
		{
			return nullptr;
		}

		return Attacks[Index];
	}
}

/**
 * Combined Animation with MetaData
 */
struct FDragonSwordCombatAttackAnimationWithMetaData
{
	UPROPERTY(EditDefaultsOnly)
	FName AnimationName;

	UPROPERTY(EditDefaultsOnly)
	FHazePlaySequenceData Animation;

	UPROPERTY(EditDefaultsOnly)
	FDragonSwordCombatAttackAnimationMetaData AttackMetaData;
}

/**
 * MetaData for the Attack animation
 */
struct FDragonSwordCombatAttackAnimationMetaData
{
	// Duration of the attack and accompanying animation.
	UPROPERTY(EditDefaultsOnly)
	float Duration = 0.5;

	// How much damage the attack does.
	UPROPERTY(EditDefaultsOnly)
	float Damage = 0.4;

	// Total amount of units we move over the animation length, temporary until root motion can be retrieved.
	UPROPERTY(EditDefaultsOnly)
	float MovementLength = 150.0;

	UPROPERTY(EditDefaultsOnly)
	EDragonSwordCombatAttackDataHitType HitType;

	UPROPERTY(EditDefaultsOnly)
	float AdditionalMovementDuration = 0.62;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ForceFeedbackEffect;
}