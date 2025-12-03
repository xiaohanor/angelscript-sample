enum ESketchbookCrabBossSubPhase
{
	None,
	Bury,
	Chasing,
	Jump,
	MoveToEdge,
	Shoot
}

class USketchbookCrabBossComponent : USketchbookBossComponent
{
	ESketchbookCrabBossSubPhase SubPhase = ESketchbookCrabBossSubPhase::Bury;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem JumpOutEffect;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem BuryEffect;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> JumpOutCameraShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect JumpOutForceFeedback;

	const float JumpVelocity = 200;
	const float BuryDepth = 350;
	const float CameraBuryDepth = 0;
	const float BurySpeed = 1000;
	const float HorizontalMoveSpeed = 600;

	bool bIsUnderground = false;
	bool bMainSequenceActive = false;
	
	float ProjectileFiringYaw = 80;
	float TargetProjectilePositionY;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		SketchbookBoss::GetSketchbookBossFightManager().OnBossPhaseSlain.AddUFunction(this, n"ResetCamera");
		Boss.Mesh.SetAbsolute(true);
	}

	void StartMainAttackSequence() override
	{
		Super::StartMainAttackSequence();

		if(!bIsUnderground)
			SubPhase = ESketchbookCrabBossSubPhase::Bury;
		else
			SubPhase = ESketchbookCrabBossSubPhase::MoveToEdge;

		bMainSequenceActive = true;
	}

	void EndMainAttackSequence() override
	{
		Super::EndMainAttackSequence();
		SubPhase = ESketchbookCrabBossSubPhase::Bury;
		bMainSequenceActive = false;
	}

	UFUNCTION()
	private void ResetCamera(ESketchbookBossChoice BossType)
	{
		auto BossFightManager = SketchbookBoss::GetSketchbookBossFightManager();
		BossFightManager.SetNewCameraTargetLocation(BossFightManager.CameraDefaultLocation);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Boss.Mesh.SetWorldLocation(Boss.ActorLocation - FVector(500, 0, 0));
	}
}