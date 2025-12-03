class UAnimInstanceSketchbookNunchuck : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Mh;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bAttackThisTick;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	UAnimSequence AttackAnim;

	USketchbookMeleeAttackPlayerComponent PlayerAttackComp;
	UPlayerMovementComponent MoveComp;

	/** List of attack sequences to randomize from */
	UPROPERTY(EditDefaultsOnly, Category = "Attacks")
	TArray<FSketchbookMeleeAttackAnimSequence> AttackSequences;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence AirAttack;

	UPROPERTY(EditDefaultsOnly)
	FVector HandleScale = FVector(1, 1, 1);

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsAirAttack;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bUpdatePose;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsAttacking;

	float UpdatePoseTimer;

	float ATTACK_POSE_INTERVAL = 0.03;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (HazeOwningActor == nullptr)
			return;

		PlayerAttackComp = USketchbookMeleeAttackPlayerComponent::GetOrCreate(HazeOwningActor);
		MoveComp = UPlayerMovementComponent::Get(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (HazeOwningActor == nullptr)
			return;

		bUpdatePose = false;
		bAttackThisTick = GetAnimTrigger(n"Attack");

		if (bAttackThisTick)
		{
			UpdatePoseTimer = ATTACK_POSE_INTERVAL;
			bIsAttacking = true;
			bUpdatePose = true;

			bIsAirAttack = MoveComp.IsInAir();

			const int AttackSequenceIndex = PlayerAttackComp.AnimData.SequenceIndex;
			if (AttackSequences.IsValidIndex(AttackSequenceIndex))
			{
				const auto Sequence = AttackSequences[AttackSequenceIndex];
				const int AttackIndex = PlayerAttackComp.AnimData.AttackIndex;
				if (Sequence.Sequence.IsValidIndex(AttackIndex))
				{
					AttackAnim = Sequence.Sequence[AttackIndex].Animation.Sequence;
				}
			}

			return;
		}

		
		if (bIsAttacking || UpdatePoseTimer > 0)
		{
			UpdatePoseTimer -= DeltaTime;
			if (UpdatePoseTimer <= 0)
			{
				bUpdatePose = true;
				UpdatePoseTimer = ATTACK_POSE_INTERVAL;
			}
		}

		// If player is moving, update
		auto PlayerCharacter = Cast<AHazePlayerCharacter>(HazeOwningActor);
		if (!PlayerCharacter.Mesh.HasAnimationStatus(n"SketchbookAttack"))
		{
			bUpdatePose = true;
			bIsAttacking = false;
			return;
		}
	}

	UFUNCTION()
	void AnimNotify_AttackStopped()
	{
		bIsAttacking = false;
	}

}