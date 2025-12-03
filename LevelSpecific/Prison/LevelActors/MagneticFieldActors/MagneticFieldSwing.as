UCLASS(Abstract)
class AMagneticFieldSwing : AMagneticFieldAxisRotateActor
{
	UPROPERTY(DefaultComponent, Attach = AxisRotateComp)
	USceneComponent ArmRoot;

	UPROPERTY(DefaultComponent, Attach = ArmRoot)
	USceneComponent PlatformRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	USceneComponent BridgeRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UBoxComponent BotTrigger;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike BridgeTimeLike;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> ImpactCamShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ImpactFF;

	bool bResetting = false;

	float DefaultSpringStrenth;

	bool bRecentlyBursted = false;
	float TimeSinceBurst = 0.0;
	float ResetDuration = 4.0;

	bool bMagnetizable = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		PlatformRoot.SetWorldRotation(FRotator(0.0, PlatformRoot.WorldRotation.Yaw, 0.0));
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		MagneticFieldResponseComp.SetMagnetizedStatus(false);

		AxisRotateComp.OnMinConstraintHit.AddUFunction(this, n"MinConstraintHit");
		AxisRotateComp.OnMaxConstraintHit.AddUFunction(this, n"MaxConstraintHit");

		BotTrigger.OnComponentBeginOverlap.AddUFunction(this, n"BotEnterTrigger");
		BotTrigger.OnComponentEndOverlap.AddUFunction(this, n"BotLeaveTrigger");

		DefaultSpringStrenth = AxisRotateComp.SpringStrength;

		MagneticFieldResponseComp.OnBurst.AddUFunction(this, n"MagnetBurst");

		BridgeTimeLike.BindUpdate(this, n"UpdateBridge");
	}

	void OpenBridge()
	{
		BridgeTimeLike.Play();

		UMagneticFieldSwingEffectEventHandler::Trigger_OpenBridge(this);
	}

	void CloseBridge()
	{
		BridgeTimeLike.Reverse();

		UMagneticFieldSwingEffectEventHandler::Trigger_CloseBridge(this);
	}

	UFUNCTION()
	private void UpdateBridge(float CurValue)
	{
		float Rot = Math::Lerp(0.0, -90.0, CurValue);
		BridgeRoot.SetRelativeRotation(FRotator(0.0, 0.0, Rot));
	}

	UFUNCTION()
	private void MagnetBurst(FMagneticFieldData Data)
	{
		bResetting = false;
		AxisRotateComp.SpringStrength = 0.0;
		TimeSinceBurst = 0.0;
		bRecentlyBursted = true;

		UMagneticFieldSwingEffectEventHandler::Trigger_StartSwingForward(this);
	}

	UFUNCTION()
	private void BotEnterTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		ATazerBot Bot = Cast<ATazerBot>(OtherActor);
		if (Bot == nullptr)
			return;

		if (OtherComp != Bot.CapsuleCollider)
			return;

		UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Bot);
		MoveComp.ApplyFollowEnabledOverride(this, EMovementFollowEnabledStatus::FollowEnabled);
		MoveComp.FollowComponentMovement(PlatformRoot, this);

		StartResetting();
	}

	UFUNCTION()
	private void BotLeaveTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		ATazerBot Bot = Cast<ATazerBot>(OtherActor);
		if (Bot == nullptr)
			return;

		if (OtherComp != Bot.CapsuleCollider)
			return;

		UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Bot);
		MoveComp.ClearFollowEnabledOverride(this);
		MoveComp.UnFollowComponentMovement(this);
	}

	UFUNCTION()
	private void MinConstraintHit(float Strength)
	{
		bResetting = false;

		OpenBridge();

		PlayImpactFeedback();

		UMagneticFieldSwingEffectEventHandler::Trigger_HitBottom(this);
	}

	UFUNCTION()
	private void MaxConstraintHit(float Strength)
	{
		PlayImpactFeedback();

		UMagneticFieldSwingEffectEventHandler::Trigger_HitTop(this);
	}

	void PlayImpactFeedback()
	{
		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.PlayWorldCameraShake(ImpactCamShake, this, PlatformRoot.WorldLocation, 800.0, 1200.0);

		ForceFeedback::PlayWorldForceFeedback(ImpactFF, PlatformRoot.WorldLocation, true, this, 800.0, 400.0);
	}

	UFUNCTION()
	void StartResetting()
	{
		if (bResetting)
			return;

		bRecentlyBursted = false;
		bResetting = true;
		AxisRotateComp.Wake();
		SetActorTickEnabled(true);

		CloseBridge();

		UMagneticFieldSwingEffectEventHandler::Trigger_StartSwingBackward(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Super::Tick(DeltaTime);

		PlatformRoot.SetWorldRotation(FRotator(0.0, PlatformRoot.WorldRotation.Yaw, 0.0));

		if (bRecentlyBursted)
		{
			TimeSinceBurst += DeltaTime;
			AxisRotateComp.ApplyAngularForce(-7.0);

			if (TimeSinceBurst >= ResetDuration)
				StartResetting();
		}

		if (bResetting)
		{
			AxisRotateComp.SpringStrength = Math::FInterpTo(AxisRotateComp.SpringStrength, DefaultSpringStrenth, DeltaTime, 1.2);
			AxisRotateComp.ApplyAngularForce(1.5);
		}
	}

	UFUNCTION()
	void MakeMagnetizable()
	{
		bMagnetizable = true;
		MagneticFieldResponseComp.SetMagnetizedStatus(true);
	}

	UFUNCTION()
	void MakeUnmagnetizable()
	{
		MagneticFieldResponseComp.SetMagnetizedStatus(false);
	}
}

class UMagneticFieldSwingEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void StartSwingForward() {}
	UFUNCTION(BlueprintEvent)
	void HitBottom() {}
	UFUNCTION(BlueprintEvent)
	void OpenBridge() {}
	UFUNCTION(BlueprintEvent)
	void CloseBridge() {}
	UFUNCTION(BlueprintEvent)
	void StartSwingBackward() {}
	UFUNCTION(BlueprintEvent)
	void HitTop() {}
}