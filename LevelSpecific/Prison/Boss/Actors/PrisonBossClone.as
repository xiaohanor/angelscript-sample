UCLASS(Abstract)
class APrisonBossClone : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeCapsuleCollisionComponent CapsuleComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeOffsetComponent MeshOffsetComp;

	UPROPERTY(DefaultComponent, Attach = MeshOffsetComp)
	UHazeCharacterSkeletalMeshComponent SkelMeshComp;
	default SkelMeshComp.bNoSkeletonUpdate = true;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence SpawnAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence MhAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence TelegraphAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence AttackAnim;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDamageEffect> DamageEffect;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	bool bReachedEnd = false;
	FVector TargetLocation;

	bool bAttacking = false;
	float WindUpTime = 0.6;
	float CurrentAttackDuration = 0.0;

	APrisonBoss Boss = nullptr;

	void Spawn(bool bFinalClone)
	{
		SkelMeshComp.bNoSkeletonUpdate = true;
		UPrisonBossCloneEffectEventHandler::Trigger_Spawn(this);
	}

	void Attack()
	{
		SkelMeshComp.bNoSkeletonUpdate = false;

		TargetLocation = ActorLocation + (ActorForwardVector * 4000.0);

		FHazeAnimationDelegate TelegraphEnterFinishedDelegate;
		TelegraphEnterFinishedDelegate.BindUFunction(this, n"TelegraphEnterFinished");
		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = TelegraphAnim;
		SkelMeshComp.PlaySlotAnimation(FHazeAnimationDelegate(), TelegraphEnterFinishedDelegate, AnimParams);

		UPrisonBossCloneEffectEventHandler::Trigger_Attack(this);
		UPrisonBossEffectEventHandler::Trigger_CloneAttack(Boss, FPrisonBossCloneAttackEventData(this));
	}
	
	UFUNCTION()
	private void TelegraphEnterFinished()
	{
		TriggerAttack();
		SetActorTickEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bReachedEnd)
			return;

		if (!bAttacking)
		{
			if (CurrentAttackDuration <= WindUpTime)
			{
				CurrentAttackDuration += DeltaTime;
				return;
			}
			else
				bAttacking = true;
		}

		FVector Loc = Math::VInterpConstantTo(ActorLocation, TargetLocation, DeltaTime, PrisonBoss::CloneAttackSpeed);
		SetActorLocation(Loc);

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
		Trace.UseBoxShape(FVector(200.0, 60.0, 200.0), ActorQuat);

		FOverlapResultArray OverlapResults = Trace.QueryOverlaps(SkelMeshComp.GetSocketLocation(n"Hips"));

		for (FOverlapResult Overlap : OverlapResults)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Overlap.Actor);
			if (Player != nullptr)
			{
				Player.DamagePlayerHealth(1.0/3.0, FPlayerDeathDamageParams(ActorForwardVector), DamageEffect, DeathEffect);
			}
		}

		if (Loc.Equals(TargetLocation))
			ReachedEnd();
	}

	void TriggerAttack()
	{
		if (bAttacking)
			return;

		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = AttackAnim;
		AnimParams.PlayRate = 0.95;
		SkelMeshComp.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), AnimParams);
	}

	void ReachedEnd()
	{
		bReachedEnd = true;
		DestroyClone();
	}

	void DestroyClone()
	{
		UPrisonBossCloneEffectEventHandler::Trigger_Destroy(this);

		BP_DestroyClone();
		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	void BP_DestroyClone() {}
}