struct FLocomotionFeatureGravityBladeCombatAnimData
{
	//UPROPERTY(Category = "GravityBladeCombat|Attacks")
	//FGravityBladeAttackSequenceData StillAttacks;

	UPROPERTY(Category = "GravityBladeCombat|Attacks")
	FGravityBladeAttackDefinition GroundAttacks;

	UPROPERTY(Category = "GravityBladeCombat|Attacks")
	FGravityBladeAttackDefinition SprintAttacks;

	UPROPERTY(Category = "GravityBladeCombat|Attacks")
	FGravityBladeAttackDefinition AirAttacks;

	UPROPERTY(Category = "GravityBladeCombat|Attacks")
	FGravityBladeAttackDefinition AirSlamAttacks;

	UPROPERTY(Category = "GravityBladeCombat|Attacks")
	FGravityBladeAttackDefinition DashAttacks;

	UPROPERTY(Category = "GravityBladeCombat|Attacks")
	FGravityBladeAttackDefinition DashTurnaroundAttacks;

	UPROPERTY(Category = "GravityBladeCombat|Attacks")
	FGravityBladeAttackDefinition RollDashAttacks;

	UPROPERTY(Category = "GravityBladeCombat|Attacks")
	FGravityBladeAttackDefinition RollDashJumpAttacks;

	UPROPERTY(Category = "GravityBladeCombat|Attacks")
	FGravityBladeAttackDefinition AirDashAttacks;

	UPROPERTY(Category = "GravityBladeCombat|Attacks")
	FGravityBladeAttackDefinition GroundRushAttacks;

	UPROPERTY(Category = "GravityBladeCombat|Attacks")
	FGravityBladeAttackDefinition AirRushAttacks;

	UPROPERTY(Category = "GravityBladeCombat", EditFixedSize, Meta = (ArraySizeEnum = "/Script/Angelscript.EGravityBladeCombatInteractionType"))
	TArray<FGravityBladeAttackSequenceData> InteractionGroundAttacks;

	UPROPERTY(Category = "GravityBladeCombat", EditFixedSize, Meta = (ArraySizeEnum = "/Script/Angelscript.EGravityBladeCombatInteractionType"))
	TArray<FGravityBladeAttackSequenceData> InteractionAirAttacks;

	UPROPERTY(Category = "GravityBladeCombat|Rush")
	FHazePlayBlendSpaceData RushLFoot;

	UPROPERTY(Category = "GravityBladeCombat|Rush")
	FHazePlayBlendSpaceData RushRFoot;

	UPROPERTY(Category = "GravityBladeCombat|Rush")
	float GroundRushAnticipationDelay = 0.5;

	UPROPERTY(Category = "GravityBladeCombat|Rush")
	FHazePlayBlendSpaceData AirRushLFoot;

	UPROPERTY(Category = "GravityBladeCombat|Rush")
	FHazePlayBlendSpaceData AirRushRFoot;

	UPROPERTY(Category = "GravityBladeCombat|Rush")
	float AirRushAnticipationDelay = 0.5;

	UPROPERTY(Category = "GravityBladeCombat|Recoils")
	FHazePlaySequenceData GroundedRecoilVar1;

	UPROPERTY(Category = "GravityBladeCombat|Recoils")
	FHazePlaySequenceData GroundedRecoilVar2;
}

class ULocomotionFeatureGravityBladeCombat : UHazeLocomotionFeatureBase
{
	default Tag = n"GravityBladeCombat";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureGravityBladeCombatAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
	FGravityBladeAttackSequenceData GetSequenceFromAttackType(EGravityBladeAttackAnimationType AttackType, int SequenceIndex) const
	{
		switch(AttackType)
		{
			case EGravityBladeAttackAnimationType::GroundAttack:
				return AnimData.GroundAttacks.Sequences[SequenceIndex];
			case EGravityBladeAttackAnimationType::SprintAttack:
				return AnimData.SprintAttacks.Sequences[SequenceIndex];
			case EGravityBladeAttackAnimationType::AirAttack:
				return AnimData.AirAttacks.Sequences[SequenceIndex];
			case EGravityBladeAttackAnimationType::AirSlamAttack:
				return AnimData.AirSlamAttacks.Sequences[SequenceIndex];
			case EGravityBladeAttackAnimationType::DashAttack:
				return AnimData.DashAttacks.Sequences[SequenceIndex];
			case EGravityBladeAttackAnimationType::DashTurnaroundAttack:
				return AnimData.DashTurnaroundAttacks.Sequences[SequenceIndex];
			case EGravityBladeAttackAnimationType::RollDashAttack:
				return AnimData.RollDashAttacks.Sequences[SequenceIndex];
			case EGravityBladeAttackAnimationType::RollDashJumpAttack:
				return AnimData.RollDashJumpAttacks.Sequences[SequenceIndex];
			case EGravityBladeAttackAnimationType::AirDashAttack:
				return AnimData.AirDashAttacks.Sequences[SequenceIndex];
			case EGravityBladeAttackAnimationType::GroundRushAttack:
				return AnimData.GroundRushAttacks.Sequences[SequenceIndex];
			case EGravityBladeAttackAnimationType::AirRushAttack:
				return AnimData.AirRushAttacks.Sequences[SequenceIndex];
			case EGravityBladeAttackAnimationType::Interaction_Air_LadderKick:
				return AnimData.InteractionAirAttacks[0];
			case EGravityBladeAttackAnimationType::Interaction_Air_LockBreak:
				return AnimData.InteractionAirAttacks[1];
			case EGravityBladeAttackAnimationType::Interaction_Air_Uppercut:
				return AnimData.InteractionAirAttacks[2];
			case EGravityBladeAttackAnimationType::Interaction_Air_Horizontal_Left:
				return AnimData.InteractionAirAttacks[3];
			case EGravityBladeAttackAnimationType::Interaction_Air_Horizontal_Right:
				return AnimData.InteractionAirAttacks[4];
			case EGravityBladeAttackAnimationType::Interaction_Air_Vertical_Up:
				return AnimData.InteractionAirAttacks[5];
			case EGravityBladeAttackAnimationType::Interaction_Air_Vertical_Down:
				return AnimData.InteractionAirAttacks[6];
			case EGravityBladeAttackAnimationType::Interaction_Air_Vertical_High:
				return AnimData.InteractionAirAttacks[7];
			case EGravityBladeAttackAnimationType::Interaction_Air_Diagonal_UpRight:
				return AnimData.InteractionAirAttacks[8];
			case EGravityBladeAttackAnimationType::Interaction_Air_Horizontal_Swing:
				return AnimData.InteractionAirAttacks[9];
			case EGravityBladeAttackAnimationType::Interaction_Air_BallBoss_Swing:
				return AnimData.InteractionAirAttacks[10];
			case EGravityBladeAttackAnimationType::Interaction_Ground_LadderKick:
				return AnimData.InteractionGroundAttacks[0];
			case EGravityBladeAttackAnimationType::Interaction_Ground_LockBreak:
				return AnimData.InteractionGroundAttacks[1];
			case EGravityBladeAttackAnimationType::Interaction_Ground_Uppercut:
				return AnimData.InteractionGroundAttacks[2];
			case EGravityBladeAttackAnimationType::Interaction_Ground_Horizontal_Left:
				return AnimData.InteractionGroundAttacks[3];
			case EGravityBladeAttackAnimationType::Interaction_Ground_Horizontal_Right:
				return AnimData.InteractionGroundAttacks[4];
			case EGravityBladeAttackAnimationType::Interaction_Ground_Vertical_Up:
				return AnimData.InteractionGroundAttacks[5];
			case EGravityBladeAttackAnimationType::Interaction_Ground_Vertical_Down:
				return AnimData.InteractionGroundAttacks[6];
			case EGravityBladeAttackAnimationType::Interaction_Ground_Vertical_High:
				return AnimData.InteractionGroundAttacks[7];
			case EGravityBladeAttackAnimationType::Interaction_Ground_Diagonal_UpRight:
				return AnimData.InteractionGroundAttacks[8];
			case EGravityBladeAttackAnimationType::Interaction_Ground_Horizontal_Swing:
				return AnimData.InteractionGroundAttacks[9];
			case EGravityBladeAttackAnimationType::Interaction_Ground_BallBoss_Swing:
				return AnimData.InteractionGroundAttacks[10];
			
		}
	}

	FGravityBladeAttackDefinition GetAttackDefinitionFromAttackType(EGravityBladeAttackAnimationType AttackType) const
	{
		switch(AttackType)
		{
			case EGravityBladeAttackAnimationType::GroundAttack:
				return AnimData.GroundAttacks;
			case EGravityBladeAttackAnimationType::SprintAttack:
				return AnimData.SprintAttacks;
			case EGravityBladeAttackAnimationType::AirAttack:
				return AnimData.AirAttacks;
			case EGravityBladeAttackAnimationType::AirSlamAttack:
				return AnimData.AirSlamAttacks;
			case EGravityBladeAttackAnimationType::DashAttack:
				return AnimData.DashAttacks;
			case EGravityBladeAttackAnimationType::DashTurnaroundAttack:
				return AnimData.DashTurnaroundAttacks;
			case EGravityBladeAttackAnimationType::RollDashAttack:
				return AnimData.RollDashAttacks;
			case EGravityBladeAttackAnimationType::RollDashJumpAttack:
				return AnimData.RollDashJumpAttacks;
			case EGravityBladeAttackAnimationType::AirDashAttack:
				return AnimData.AirDashAttacks;
			case EGravityBladeAttackAnimationType::GroundRushAttack:
				return AnimData.GroundRushAttacks;
			case EGravityBladeAttackAnimationType::AirRushAttack:
				return AnimData.AirRushAttacks;

			case EGravityBladeAttackAnimationType::Interaction_Air_LadderKick:
			{
				FGravityBladeAttackDefinition Definition;
				Definition.Sequences.Add(AnimData.InteractionAirAttacks[0]);
				return Definition;
			}
			case EGravityBladeAttackAnimationType::Interaction_Air_LockBreak:
			{
				FGravityBladeAttackDefinition Definition;
				Definition.Sequences.Add(AnimData.InteractionAirAttacks[1]);
				return Definition;
			}
			case EGravityBladeAttackAnimationType::Interaction_Air_Uppercut:
			{
				FGravityBladeAttackDefinition Definition;
				Definition.Sequences.Add(AnimData.InteractionAirAttacks[2]);
				return Definition;
			}
			case EGravityBladeAttackAnimationType::Interaction_Air_Horizontal_Left:
			{
				FGravityBladeAttackDefinition Definition;
				Definition.Sequences.Add(AnimData.InteractionAirAttacks[3]);
				return Definition;
			}
			case EGravityBladeAttackAnimationType::Interaction_Air_Horizontal_Right:
			{
				FGravityBladeAttackDefinition Definition;
				Definition.Sequences.Add(AnimData.InteractionAirAttacks[4]);
				return Definition;
			}
			case EGravityBladeAttackAnimationType::Interaction_Air_Vertical_Up:
			{
				FGravityBladeAttackDefinition Definition;
				Definition.Sequences.Add(AnimData.InteractionAirAttacks[5]);
				return Definition;
			}
			case EGravityBladeAttackAnimationType::Interaction_Air_Vertical_Down:
			{
				FGravityBladeAttackDefinition Definition;
				Definition.Sequences.Add(AnimData.InteractionAirAttacks[6]);
				return Definition;
			}
			case EGravityBladeAttackAnimationType::Interaction_Air_Vertical_High:
			{
				FGravityBladeAttackDefinition Definition;
				Definition.Sequences.Add(AnimData.InteractionAirAttacks[7]);
				return Definition;
			}
			case EGravityBladeAttackAnimationType::Interaction_Air_Diagonal_UpRight:
			{
				FGravityBladeAttackDefinition Definition;
				Definition.Sequences.Add(AnimData.InteractionAirAttacks[8]);
				return Definition;
			}
			case EGravityBladeAttackAnimationType::Interaction_Air_Horizontal_Swing:
			{
				FGravityBladeAttackDefinition Definition;
				Definition.Sequences.Add(AnimData.InteractionAirAttacks[9]);
				return Definition;
			}
			case EGravityBladeAttackAnimationType::Interaction_Air_BallBoss_Swing:
			{
				FGravityBladeAttackDefinition Definition;
				Definition.Sequences.Add(AnimData.InteractionAirAttacks[10]);
				return Definition;
			}
			case EGravityBladeAttackAnimationType::Interaction_Ground_LadderKick:
			{
				FGravityBladeAttackDefinition Definition;
				Definition.Sequences.Add(AnimData.InteractionGroundAttacks[0]);
				return Definition;
			}
			case EGravityBladeAttackAnimationType::Interaction_Ground_LockBreak:
			{
				FGravityBladeAttackDefinition Definition;
				Definition.Sequences.Add(AnimData.InteractionGroundAttacks[1]);
				return Definition;
			}
			case EGravityBladeAttackAnimationType::Interaction_Ground_Uppercut:
			{
				FGravityBladeAttackDefinition Definition;
				Definition.Sequences.Add(AnimData.InteractionGroundAttacks[2]);
				return Definition;
			}
			case EGravityBladeAttackAnimationType::Interaction_Ground_Horizontal_Left:
			{
				FGravityBladeAttackDefinition Definition;
				Definition.Sequences.Add(AnimData.InteractionGroundAttacks[3]);
				return Definition;
			}
			case EGravityBladeAttackAnimationType::Interaction_Ground_Horizontal_Right:
			{
				FGravityBladeAttackDefinition Definition;
				Definition.Sequences.Add(AnimData.InteractionGroundAttacks[4]);
				return Definition;
			}
			case EGravityBladeAttackAnimationType::Interaction_Ground_Vertical_Up:
			{
				FGravityBladeAttackDefinition Definition;
				Definition.Sequences.Add(AnimData.InteractionGroundAttacks[5]);
				return Definition;
			}
			case EGravityBladeAttackAnimationType::Interaction_Ground_Vertical_Down:
			{
				FGravityBladeAttackDefinition Definition;
				Definition.Sequences.Add(AnimData.InteractionGroundAttacks[6]);
				return Definition;
			}
			case EGravityBladeAttackAnimationType::Interaction_Ground_Vertical_High:
			{
				FGravityBladeAttackDefinition Definition;
				Definition.Sequences.Add(AnimData.InteractionGroundAttacks[7]);
				return Definition;
			}
			case EGravityBladeAttackAnimationType::Interaction_Ground_Diagonal_UpRight:
			{
				FGravityBladeAttackDefinition Definition;
				Definition.Sequences.Add(AnimData.InteractionGroundAttacks[8]);
				return Definition;
			}
			case EGravityBladeAttackAnimationType::Interaction_Ground_Horizontal_Swing:
			{
				FGravityBladeAttackDefinition Definition;
				Definition.Sequences.Add(AnimData.InteractionGroundAttacks[9]);
				return Definition;
			}
			case EGravityBladeAttackAnimationType::Interaction_Ground_BallBoss_Swing:
			{
				FGravityBladeAttackDefinition Definition;
				Definition.Sequences.Add(AnimData.InteractionGroundAttacks[10]);
				return Definition;
			}
		}
	}
}

struct FGravityBladeAttackDefinition
{
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Attack Data")
	bool bRandomizeSequenceIndex = false;
	
	// Continue the same combo across multiple sequences, instead of stopping and waiting for settle
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Attack Data")
	bool bContinueComboBetweenSequences = false;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Attack Data")
	TArray<FGravityBladeAttackSequenceData> Sequences;
}

/**
 * Defines a type of attack sequence.
 */
struct FGravityBladeAttackSequenceData
{
	// Attack data for each attack in this sequence.
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Sequence")
	TArray<FGravityBladeCombatAttackAnimationWithMetaData> Attacks;

	FGravityBladeCombatAttackAnimationWithMetaData GetAnimationFromName(FName AnimationName) const
	{
		if(Attacks.Num() == 0)
			return FGravityBladeCombatAttackAnimationWithMetaData();

		for(int i = 0; i < Attacks.Num(); i++)
		{
			if(Attacks[i].AnimationName == AnimationName)
				return Attacks[i];
		}

		return Attacks[0];
	}

	FGravityBladeCombatAttackAnimationWithMetaData GetAnimationFromIndex(int Index) const
	{
		if(Attacks.Num() == 0)
			return FGravityBladeCombatAttackAnimationWithMetaData();

		if(Index < 0 || Index >= Attacks.Num())
			return FGravityBladeCombatAttackAnimationWithMetaData();

		return Attacks[Index];
	}
}

/**
 * Combined Animation with MetaData
 */
struct FGravityBladeCombatAttackAnimationWithMetaData
{
	UPROPERTY(EditDefaultsOnly)
	FName AnimationName;

	UPROPERTY(EditDefaultsOnly)
	FHazePlaySequenceData Animation;

	UPROPERTY(EditDefaultsOnly)
	FGravityBladeCombatAttackAnimationMetaData AttackMetaData;
}

enum EGravityBladeCombatAnimationFootOverride
{
	/* Automatic means the foot forward will be automatically checked based on the first frame of the UAnimSequence */
	Automatic,
	/* Manually specify the animation has left foot forward */
	Left,
	/* Manually specify the animation has right foot forward */
	Right
}

/**
 * MetaData for the Attack animation
 */
struct FGravityBladeCombatAttackAnimationMetaData
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
	bool bIsSpin = false;

	/* Either the foot forward will be determined automatically from the first frame of the animation or it will be manually overriden with this */
	UPROPERTY(EditDefaultsOnly)
	EGravityBladeCombatAnimationFootOverride AnimationFootOverride = EGravityBladeCombatAnimationFootOverride::Automatic;
}