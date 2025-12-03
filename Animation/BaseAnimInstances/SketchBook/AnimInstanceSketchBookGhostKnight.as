class UAnimInstanceSketchBookGhostKnight : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Mh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Fwd;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Attack;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData AttackAnticipation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsMoving;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bAttack;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bAttackAnticipation;

	ASketchbookSimpleEnemy SimpleEnemy;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (HazeOwningActor == nullptr)
			return;

		SimpleEnemy = Cast<ASketchbookSimpleEnemy>(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (SimpleEnemy == nullptr)
			return;

		bIsMoving = SimpleEnemy.EnemyState == ESketchBookSimpleEnemyState::Moving;

		bAttack = GetAnimTrigger(n"Attack");

		if (SimpleEnemy.TargetActor != nullptr)
		{
			const float TargetDistance = (HazeOwningActor.ActorLocation - SimpleEnemy.TargetActor.ActorLocation).Size();
			if (TargetDistance < 240)
				bAttackAnticipation = true;
			else if (TargetDistance > 240 + 100)
				bAttackAnticipation = false;
		}
	}
}