struct FGravityBladeRecoilData
{
	float StartTimestamp = -1.0;
	float Duration = -1.0;
	FVector Direction = FVector::ZeroVector;

	float GetEndTimestamp() const property
	{
		return StartTimestamp + Duration;
	}
}

enum EGravityBladeAttackMovementType
{
	Ground,
	Air,
	AirHover,
	AirSlam,
	GroundRush,
	AirRush,
	OpportunityAttack,
}

enum EGravityBladeAttackAnimationType
{
	GroundAttack,
	SprintAttack,
	AirAttack,
	AirSlamAttack,
	DashAttack,
	DashTurnaroundAttack,
	RollDashAttack,
	RollDashJumpAttack,
	AirDashAttack,
	GroundRushAttack,
	AirRushAttack,

	Interaction_Air_LadderKick,
	Interaction_Air_LockBreak,
	Interaction_Air_Uppercut,
	Interaction_Air_Horizontal_Left,
	Interaction_Air_Horizontal_Right,
	Interaction_Air_Vertical_Up,
	Interaction_Air_Vertical_Down,
	Interaction_Air_Vertical_High,
	Interaction_Air_Diagonal_UpRight,
	Interaction_Air_Horizontal_Swing,
	Interaction_Air_BallBoss_Swing,

	Interaction_Ground_LadderKick,
	Interaction_Ground_LockBreak,
	Interaction_Ground_Uppercut,
	Interaction_Ground_Horizontal_Left,
	Interaction_Ground_Horizontal_Right,
	Interaction_Ground_Vertical_Up,	
	Interaction_Ground_Vertical_Down,
	Interaction_Ground_Vertical_High,
	Interaction_Ground_Diagonal_UpRight,
	Interaction_Ground_Horizontal_Swing,
	Interaction_Ground_BallBoss_Swing,
}

enum EGravityBladeCombatDashType
{
	None,
	Dash,
	RollDash,
	AirDash,
	RollDashJump,
}

enum EGravityBladeCombatAttackDataType
{
	Invalid,
	Pending,
	Active,
	Previous
}

// The active (or pending) attacking state
// Used for selecting what Rush/Attack capability to run
struct FGravityBladeCombatAttackData
{
	EGravityBladeCombatAttackDataType AttackDataType;

	EGravityBladeAttackMovementType MovementType;
	EGravityBladeAttackAnimationType AnimationType;

	private bool bIsValid = false;
	private UGravityBladeCombatTargetComponent Target_Internal;
	private FGravityBladeCombatAttackAnimationData AnimationData_Internal;

	FGravityBladeCombatAttackData(EGravityBladeAttackMovementType InMovementType, EGravityBladeAttackAnimationType InAnimationType, UGravityBladeCombatTargetComponent InTarget, FGravityBladeCombatAttackAnimationData InAnimationData)
	{
		if(!InAnimationData.IsValid())
			return;

		MovementType = InMovementType;
		AnimationType = InAnimationType;
		Target_Internal = InTarget;
		AnimationData_Internal = InAnimationData;

		bIsValid = true;
	}

	bool IsValid() const
	{
		if(!bIsValid)
			return false;

		if(!AnimationData_Internal.IsValid())
			return false;

		return true;
	}

	void Invalidate()
	{
		check(bIsValid);

		bIsValid = false;
	}
	
	UGravityBladeCombatTargetComponent GetTarget() const property
	{
		check(IsValid());
		return Target_Internal;
	}

	FGravityBladeCombatAttackAnimationData GetAnimationData() const property
	{
		check(IsValid());
		return AnimationData_Internal;
	}

	FGravityBladeAttackSequenceData GetSequence() const property
	{
		check(IsValid());
		return AnimationData_Internal.Sequence;
	}

	bool IsRushAttack() const
	{
		return MovementType == EGravityBladeAttackMovementType::AirRush || MovementType == EGravityBladeAttackMovementType::GroundRush;
	}

	int GetAttackIndex() const property
	{
		check(IsValid());
		return AnimationData_Internal.AttackIndex;
	}

	int GetSequenceIndex() const property
	{
		check(IsValid());
		return AnimationData_Internal.SequenceIndex;
	}
}