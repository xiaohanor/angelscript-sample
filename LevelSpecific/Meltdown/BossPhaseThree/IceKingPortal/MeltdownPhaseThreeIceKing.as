UCLASS(Abstract)
class AMeltdownPhaseThreeIceKing : AHazeCharacter
{
	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueue;

	UPROPERTY(DefaultComponent)
	UDamageTriggerComponent DamageTrigger;
	default DamageTrigger.bApplyKnockbackImpulse = true;
	default DamageTrigger.HorizontalKnockbackStrength = 2000.0;
	default DamageTrigger.VerticalKnockbackStrength = 1200.0;

	UPROPERTY(DefaultComponent, Attach = CharacterMesh0)
	UHealthBarInWorldComponent HealthBarComp;
	default HealthBarComp.MaxHealth = 150.0;
	default HealthBarComp.CurrentHealth = 150.0;

	UPROPERTY(DefaultComponent)
	UMeltdownGlitchShootingResponseComponent GlitchResponce;

	UPROPERTY(DefaultComponent, Attach = CharacterMesh0)
	UAutoAimTargetComponent AutoAim;

	UPROPERTY(DefaultComponent)
	UHazeMovementAudioComponent AudioMovementComp;

	UPROPERTY()
	UAnimSequence EnterAnim;
	UPROPERTY()
	UAnimSequence RunAnim;
	UPROPERTY()
	UAnimSequence AttackAnim;
	UPROPERTY()
	UAnimSequence RechargeAnim;

	AMeltdownPhaseThreeBoss Rader;
	AMeltdownPhaseThreeIceKingClawAttack LeftClawAttack;
	AMeltdownPhaseThreeIceKingClawAttack RightClawAttack;

	FVector StartLocation;
	FVector IdleLocation;

	float MaxSpeed = 3500.0;
	float InitialSpeed = 2500.0;
	float Acceleration = 1000.0;

	float MaxDistance = 5000;

	float Speed;
	float Distance;
	bool bIsRunning;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);

		GlitchResponce.OnGlitchHit.AddUFunction(this, n"OnHit");
		AutoAim.Disable(this);

		HealthBarComp.SetHealthBarEnabled(false);
	}

	UFUNCTION()
	private void OnHit(FMeltdownGlitchImpact Impact)
	{
		UMeltdownPhaseThreeIceKingEffectHandler::Trigger_HitByPlayerAttack(this, Impact);
		HealthBarComp.CurrentHealth -= Impact.Damage;
		if (HealthBarComp.CurrentHealth <= 0)
		{
			UMeltdownPhaseThreeIceKingEffectHandler::Trigger_DestroyedByPlayerAttack(this);
			DestroyActor();
		}
	}

	UFUNCTION()
	void LaunchFromPortal()
	{
		RemoveActorDisable(this);
		UMeltdownPhaseThreeIceKingEffectHandler::Trigger_OnAppear(this);

		LeftClawAttack = SpawnActor(Rader.ClawAttackClass);
		RightClawAttack = SpawnActor(Rader.ClawAttackClass);

		FVector LeftHand = Rader.Mesh.GetSocketLocation(n"LeftAttach");
		FVector RightHand = Rader.Mesh.GetSocketLocation(n"RightAttach");

		StartLocation = (LeftHand + RightHand) * 0.5;
		StartLocation.Z = Rader.ActorLocation.Z;

		IdleLocation = StartLocation;
		IdleLocation -= Rader.ActorForwardVector * 600.0;

		StartLocation += Rader.ActorForwardVector * 2500.0;

		// Debug::DrawDebugSphere(StartLocation, LineColor = FLinearColor::Red, Duration = 20);
		// Debug::DrawDebugSphere(IdleLocation, LineColor = FLinearColor::Green, Duration = 20);


		Speed = InitialSpeed;

		SetActorLocationAndRotation(StartLocation, FRotator::MakeFromX(-Rader.ActorForwardVector));

		ActionQueue.Event(this, n"Enter");
		ActionQueue.Duration(0.5, this, n"MoveToIdleLocation");

		// ActionQueue.Event(this, n"StartRunning");
		// ActionQueue.IdleUntil(this, n"ReachedFinalDistance");
		// ActionQueue.Event(this, n"GlitchAway");

		// ActionQueue.Event(this, n"GlitchAway");

		AutoAim.Enable(this);
		HealthBarComp.SetHealthBarEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bIsRunning)
		{
			Speed = Math::Min(Speed + Acceleration * DeltaSeconds, MaxSpeed);
			Distance += Speed*DeltaSeconds;
			SetActorLocation(ActorLocation + (ActorForwardVector*Speed*DeltaSeconds));
		}

		if (ActionQueue.IsEmpty())
		{
			ActionQueue.Event(this, n"Recharge");
			ActionQueue.Idle(2.5);

			ActionQueue.Event(this, n"StartAttack");
			ActionQueue.Idle(2.5/1.5);
			ActionQueue.Event(this, n"SpawnRightAttack");
			ActionQueue.Idle(1.9/1.5);
			ActionQueue.Event(this, n"SpawnLeftAttack");
			ActionQueue.Idle(2.27/1.5);
			ActionQueue.Event(this, n"SpawnRightAttack");
			ActionQueue.Idle(2.0/1.5);
			ActionQueue.Event(this, n"SpawnLeftAttack");
			ActionQueue.Idle(2.0/1.5);
			ActionQueue.Event(this, n"SpawnRightAttack");
			ActionQueue.Idle(1.0/1.5);
		}

		if (Rader.IsDead())
		{
			DestroyActor();
		}
	}

	UFUNCTION()
	private void Enter()
	{
		PlaySlotAnimation(Animation = RunAnim, bLoop = true);
	}

	UFUNCTION()
	private void MoveToIdleLocation(float Alpha)
	{
		float DistanceAlpha = Alpha;
		SetActorLocation(Math::Lerp(StartLocation, IdleLocation, DistanceAlpha));
	}

	UFUNCTION()
	private void StartAttack()
	{
		PlaySlotAnimation(Animation = AttackAnim);
	}

	UFUNCTION()
	private void SpawnRightAttack()
	{
		FTransform ClawTransform = Mesh.GetSocketTransform(n"RightHand");

		FVector AttackLocation = ClawTransform.Location;
		AttackLocation.Z = ActorLocation.Z;

		FQuat AttackRotation = FQuat(FVector::UpVector, 0.5) * ActorQuat;
		AttackLocation += AttackRotation.ForwardVector * 400.0;

		RightClawAttack.SetActorTransform(
			FTransform(AttackRotation, AttackLocation, FVector(0.5, 0.5, 1.0))
		);
		RightClawAttack.ActivateClawAttack();
	}

	UFUNCTION()
	private void Recharge()
	{
		PlaySlotAnimation(Animation = RechargeAnim);
	}

	UFUNCTION()
	private void SpawnLeftAttack()
	{
		FTransform ClawTransform = Mesh.GetSocketTransform(n"LeftHand");

		FVector AttackLocation = ClawTransform.Location;
		AttackLocation.Z = ActorLocation.Z;

		FQuat AttackRotation = FQuat(FVector::UpVector, -0.5) * ActorQuat;
		AttackLocation += AttackRotation.ForwardVector * 400.0;

		LeftClawAttack.SetActorTransform(
			FTransform(AttackRotation, AttackLocation, FVector(0.5, 0.5, 1.0))
		);
		LeftClawAttack.ActivateClawAttack();
	}

	UFUNCTION(BlueprintEvent)
	void BP_SpawnClawAttack()
	{
	}

	UFUNCTION()
	private void StartRunning()
	{
		PlaySlotAnimation(Animation = RunAnim, bLoop = true);
		bIsRunning = true;
	}

	UFUNCTION()
	private bool ReachedFinalDistance()
	{
		return Distance > MaxDistance;
	}

	UFUNCTION()
	private void GlitchAway()
	{
		UMeltdownPhaseThreeIceKingEffectHandler::Trigger_OnDisappear(this);
		DestroyActor();
	}
};

UCLASS(Abstract)
class UMeltdownPhaseThreeIceKingEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnAppear() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDisappear() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HitByPlayerAttack(FMeltdownGlitchImpact GlitchImpact) {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DestroyedByPlayerAttack() {}
}