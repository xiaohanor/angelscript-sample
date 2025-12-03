class AMeltdownBossPhaseThreeExecutionerSpinner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Head;
	
	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase Body;

	UPROPERTY(DefaultComponent, Attach = Head)
	UDamageTriggerComponent DamageTriggerHead;
	default DamageTriggerHead.bApplyKnockbackImpulse = true;
	default DamageTriggerHead.HorizontalKnockbackStrength = 1200;
	default DamageTriggerHead.VerticalKnockbackStrength = 1200;

	UPROPERTY(DefaultComponent, Attach = LeftEye)
	UDamageTriggerComponent LaserDamageTriggerLeft;
	UPROPERTY(DefaultComponent, Attach = RightEye)
	UDamageTriggerComponent LaserDamageTriggerRight;

	UPROPERTY(DefaultComponent, Attach = LeftEye)
	UHazeMovablePlayerTriggerComponent FeedbackTrigger;
	
	UPROPERTY(DefaultComponent, Attach = Head)
	UStaticMeshComponent LeftEye;
	default LeftEye.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = Head)
	UAutoAimTargetComponent AutoAim;

	UPROPERTY(DefaultComponent, Attach = Head)
	UStaticMeshComponent RightEye;
	default RightEye.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = Head)
	UHealthBarInWorldComponent HealthBarComp;
	default HealthBarComp.MaxHealth = 100.0;
	default HealthBarComp.CurrentHealth = 100.0;

	UPROPERTY(DefaultComponent)
	UMeltdownGlitchShootingResponseComponent GlitchResponce;

	UPROPERTY(EditAnywhere)
	ASplineActor FollowSpline;

	UPROPERTY()
	UAnimSequence BodyAnimation;

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect JumpFeedback;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> JumpShake;

	UHazeSplineComponent SplineComp;

	float CurrentSplineDistance;

	float Speed = 1500;

	float MinSpeed = 0;

	float RotationSpeed = 200.0;

	FHazeAcceleratedFloat Deceleration;
	AMeltdownPhaseThreeBoss Rader;

	FVector StartScale;

	FRotator LeftInitRot = FRotator(0,0,0);
	FRotator RightInitRot = FRotator(0,0,0);
	FRotator LeftRotationStart = FRotator(0,40,0);
	FRotator LeftRotationEnd = FRotator(0,-40,0);
	FRotator RightRotationStart = FRotator(0,-40,0);
	FRotator RightRotationEnd  = FRotator(0,40,0);
	
	UPROPERTY()
	FVector EndScale;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);
		SetActorTickEnabled(false);

		HealthBarComp.SetHealthBarEnabled(false);
		AutoAim.Disable(this);

	//	SplineComp = FollowSpline.Spline;

		LaserDamageTriggerLeft.OnPlayerDamagedByTrigger.AddUFunction(this, n"OnDamagedByLaser");
		LaserDamageTriggerRight.OnPlayerDamagedByTrigger.AddUFunction(this, n"OnDamagedByLaser");

		FeedbackTrigger.OnPlayerEnter.AddUFunction(this, n"TriggerFeedback");

		GlitchResponce.OnGlitchHit.AddUFunction(this, n"OnHitByPlayerAttack");
	}

	UFUNCTION()
	private void TriggerFeedback(AHazePlayerCharacter Player)
	{
		Player.PlayForceFeedback(JumpFeedback, false, false, this);
		Player.PlayCameraShake(JumpShake, this);
	}

	UFUNCTION()
	private void OnHitByPlayerAttack(FMeltdownGlitchImpact Impact)
	{
		UMeltdownBossPhaseThreeExecutionerSpinnerEffectHandler::Trigger_HitByPlayerAttack(this, Impact);

		HealthBarComp.CurrentHealth -= Impact.Damage;
		if (HealthBarComp.CurrentHealth <= 0.0)
		{
			UMeltdownBossPhaseThreeExecutionerSpinnerEffectHandler::Trigger_KilledByPlayers(this);
			AddActorDisable(this);
		}
	}

	UFUNCTION()
	private void OnDamagedByLaser(AHazePlayerCharacter Player)
	{
		Player.AddKnockbackImpulse(LaserDamageTriggerLeft.RightVector, 900, 1200);
	}

	void Appear()
	{
		UMeltdownBossPhaseThreeExecutionerSpinnerEffectHandler::Trigger_SpawnedByRader(this);

		HealthBarComp.SetHealthBarEnabled(false);
		AutoAim.Disable(this);

		RemoveActorDisable(this);
		SetActorTickEnabled(false);
		Head.SetRelativeLocationAndRotation(FVector::ZeroVector, FRotator::ZeroRotator);

		LeftEye.SetHiddenInGame(true);
		RightEye.SetHiddenInGame(true);
		HealthBarComp.CurrentHealth = HealthBarComp.MaxHealth;

		DamageTriggerHead.DisableDamageTrigger(this);
		LaserDamageTriggerLeft.DisableDamageTrigger(this);
		LaserDamageTriggerRight.DisableDamageTrigger(this);
	}

	void StartSpinning()
	{
		SetActorRotation(FRotator(0, 0, 0));
		SetActorTickEnabled(true);
		AutoAim.Enable(this);

		LeftEye.SetHiddenInGame(false);
		RightEye.SetHiddenInGame(false);

		DamageTriggerHead.EnableDamageTrigger(this);
		LaserDamageTriggerLeft.EnableDamageTrigger(this);
		LaserDamageTriggerRight.EnableDamageTrigger(this);
		HealthBarComp.SetHealthBarEnabled(true);

		UMeltdownBossPhaseThreeExecutionerSpinnerEffectHandler::Trigger_StartSpinning(this);
	}

	UFUNCTION()
	private void CrosseyeStartUpdate(float CurrentValue)
	{
		LeftEye.SetRelativeRotation(Math::LerpShortestPath(LeftInitRot,LeftRotationStart,CurrentValue));
		RightEye.SetRelativeRotation(Math::LerpShortestPath(RightInitRot,RightRotationStart,CurrentValue));
	}

	void StopSpinning()
	{
		AddActorDisable(this);
		UMeltdownBossPhaseThreeExecutionerSpinnerEffectHandler::Trigger_EndSpinning(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Rader.IsDead())
		{
			StopSpinning();
			return;
		}

		Head.AddLocalRotation(FRotator(0, RotationSpeed*DeltaSeconds, 0));

		FMeltdownBossPhaseThreeExecutionerSpinnerUpdateParams UpdateParams;
		UpdateParams.SpinAlpha = Math::GetMappedRangeValueClamped(
			FVector2D(4.5, 3.3),
			FVector2D(0.0, 1.0),
			RotationSpeed
		);

		UMeltdownBossPhaseThreeExecutionerSpinnerEffectHandler::Trigger_UpdateSpinning(this, UpdateParams);
	}
};

struct FMeltdownBossPhaseThreeExecutionerSpinnerUpdateParams
{
	UPROPERTY()
	float SpinAlpha;
}

UCLASS(Abstract)
class UMeltdownBossPhaseThreeExecutionerSpinnerEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SpawnedByRader() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartSpinning() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void UpdateSpinning(FMeltdownBossPhaseThreeExecutionerSpinnerUpdateParams Params) {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void EndSpinning() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HitByPlayerAttack(FMeltdownGlitchImpact Impact) {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void KilledByPlayers() {}
}