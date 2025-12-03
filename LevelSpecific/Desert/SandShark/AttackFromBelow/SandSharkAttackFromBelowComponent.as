enum ESandSharkAttackFromBelowState
{
	None,
	Dive,
	Jump,
};

UCLASS(Abstract)
class USandSharkAttackFromBelowComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly, Category="Attack from Below")
	UForceFeedbackEffect KillForceFeedback;

	UPROPERTY(EditDefaultsOnly, Category="Attack from Below", Meta = (ClampMin = "0"))
	float ForceFeedbackMaxIntensity = 1;

	ASandShark SandShark;

	// Are we currently in this state?
	bool bIsAttackingFromBelow = false;

	// What's our internal state? Are we diving or jumping?
	ESandSharkAttackFromBelowState State = ESandSharkAttackFromBelowState::None;

	// When did we last perform an attack (used to wait a while before doing another attack)
	float LastAttackFromBelowTime = -BIG_NUMBER;

	// For how long have we been diving? Used for the jump to know when to activate
	float DiveActiveDuration;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SandShark = Cast<ASandShark>(Owner);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FTemporalLog TemporalLog = TEMPORAL_LOG(SandShark).Section("AttackFromBelow");

		TemporalLog.Value(f"AttackFromBelowState", State);
		TemporalLog.Value(f"LastAttackFromBelowTime", LastAttackFromBelowTime);
		TemporalLog.Value(f"IsTargetPlayerAttackable", IsTargetPlayerAttackable());
	}
#endif

	bool IsTargetPlayerAttackable() const
	{
		if(!SandShark.HasTargetPlayer())
			return false;

		auto PlayerComp = SandShark.GetTargetPlayerComponent();

		if(PlayerComp.Player.IsPlayerDead() || PlayerComp.Player.IsPlayerRespawning())
			return false;

		auto MoveComp = UPlayerMovementComponent::Get(SandShark.GetTargetPlayer());
		if(!PlayerComp.bHasTouchedSand && MoveComp.HasGroundContact())
			return false;

		if(PlayerComp.bIsPerching)
			return false;

		if(PlayerComp.bOnSafePoint)
			return false;

		if(PlayerComp.bIsPerformingContextualMove)
			return false;

		return true;
	}
};