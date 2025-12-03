class APrisonBossChaseExecutioner : AHazeSkeletalMeshActor
{
	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueue;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000;

	UPROPERTY()
	UAnimSequence AttackSequence;
	UPROPERTY()
	UAnimSequence MHSequence;
	UPROPERTY()
	UNiagaraSystem AttackSystem;

	UPROPERTY(EditInstanceOnly)
	APlayerTrigger AttackDamageTrigger;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Mesh.HideBoneByName(n"LeftArm", EPhysBodyOp::PBO_None);
		Mesh.HideBoneByName(n"RightArm", EPhysBodyOp::PBO_None);
		Mesh.HideBoneByName(n"Head", EPhysBodyOp::PBO_None);
		Mesh.HideBoneByName(n"RightShoulderPad", EPhysBodyOp::PBO_None);

		ActionQueue.SetLooping(true);
		ActionQueue.Event(this, n"StartAttack");
		ActionQueue.Idle(1.4);
		ActionQueue.Event(this, n"StartMH");
		ActionQueue.Idle(2.0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ActionQueue.ScrubTo(Time::PredictedGlobalCrumbTrailTime);
	}

	UFUNCTION()
	private void StartAttack()
	{
		Niagara::SpawnOneShotNiagaraSystemAttached(AttackSystem, Mesh, n"HipsGear");
		UPrisonBossChaseExecutionerEventHandler::Trigger_StartThruster(this);
		PlayEventAnimation(Animation = AttackSequence);
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (AttackDamageTrigger.IsPlayerInside(Player))
			{
				Player.DamagePlayerHealth(1.0, FPlayerDeathDamageParams(-Mesh.GetSocketRotation(n"HipsGear").UpVector), DeathEffect = DeathEffect);
			}
		}
	}

	UFUNCTION()
	private void StartMH()
	{
		PlayEventAnimation(Animation = MHSequence, bLoop = true);
	}
};

class UPrisonBossChaseExecutionerEventHandler : UHazeEffectEventHandler
{
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartThruster() {}

};