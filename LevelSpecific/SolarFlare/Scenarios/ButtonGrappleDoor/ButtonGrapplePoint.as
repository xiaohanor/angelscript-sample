event void FButtonGrapplePointPressedEvent();

class AButtonGrapplePoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent ButtonMesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent BatteryPushIn;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent OverlapComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UArrowComponent ImpulseDirection;
	default ImpulseDirection.SetWorldScale3D(FVector(5.0));

	// UPROPERTY(DefaultComponent, Attach = Root)
	// UGrappleLaunchPointComponent GrapplePoint;

	UPROPERTY(EditAnywhere)
	AGrappleLaunchPoint GrappleLaunchPoint;

	UPROPERTY(EditAnywhere)
	float ForwardImpulseAmount = 400.0;

	UPROPERTY(EditAnywhere)
	float VerticalImpulseAmount = 600.0;

	UPROPERTY(EditAnywhere)
	bool bOneShot = false;

	UPROPERTY()
	UAnimSequence BackFlipAnim;

	UPROPERTY(EditAnywhere)
	UMaterialInterface ActiveMat;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY()
	UForceFeedbackEffect ForceFeedback;

	UPROPERTY()
	FButtonGrapplePointPressedEvent OnButtonPressed;

	UMaterialInterface InactiveMat;

	TArray<AHazePlayerCharacter> DisablePlayers;

	float ButtonDuration = 1.25;
	float ButtonDeactivateTime;

	UPROPERTY()
	FVector StartBatteryLocation;

	UPROPERTY(EditAnywhere, Category = "Audio")
	UHazeAudioEvent ButtonActivatedEvent = nullptr;
	
	UPROPERTY(EditAnywhere, Category = "Audio")
	UHazeAudioEvent ButtonDeactivatedEvent = nullptr;

	UPROPERTY(EditAnywhere, Category = "Audio")
	FHazeAudioFireForgetEventParams AudioEventParams;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartBatteryLocation = BatteryPushIn.RelativeLocation;
		OverlapComp.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
		OverlapComp.OnComponentEndOverlap.AddUFunction(this, n"OnComponentEndOverlap");
		InactiveMat = ButtonMesh.GetMaterial(0);
		SetActorTickEnabled(false);
		GrappleLaunchPoint.OnPlayerFinishedGrapplingToPointEvent.AddUFunction(this, n"OnPlayerFinishedGrapplingToPointEvent");


		AudioEventParams.Transform = MeshRoot.GetWorldTransform();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Time::GameTimeSeconds > ButtonDeactivateTime)
		{
			ButtonMesh.SetMaterial(0, InactiveMat);
			BP_ButtonPushedOff();

			FOnButtonGrappleImpactParams ButtonParams;
			ButtonParams.Location = ActorLocation;
			UButtonGrapplePointEffectHandler::Trigger_OnButtonGrappleReturn(this, ButtonParams);

			if(ButtonDeactivatedEvent != nullptr)
			{
				AudioComponent::PostFireForget(ButtonDeactivatedEvent, AudioEventParams);
			}

			SetActorTickEnabled(false);		
		}
	}

	UFUNCTION()
	private void OnPlayerFinishedGrapplingToPointEvent(AHazePlayerCharacter Player,
	                                                   UGrapplePointBaseComponent ActiveGrapplePoint)
	{



	}

	UFUNCTION()
	private void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                     UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                     bool bFromSweep, const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr)
		{
			if (Player.HasControl() && Player.IsAnyCapabilityActive(PlayerMovementTags::Grapple))
			{
				CrumbActivateButton(Player);
			}
		}
	}
	
	UFUNCTION()
	private void OnComponentEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                   UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr)
		{
			if (!bOneShot)
			{
				if (DisablePlayers.Contains(Player))
				{
					GrappleLaunchPoint.GrappleLaunchPoint.EnableForPlayer(Player, this);
					DisablePlayers.Remove(Player);
				}
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbActivateButton(AHazePlayerCharacter Player)
	{
		GrappleLaunchPoint.GrappleLaunchPoint.DisableForPlayer(Player, this);
		DisablePlayers.Add(Player);
		FHazePlaySlotAnimationParams Params;
		Params.Animation = BackFlipAnim;
		Player.PlaySlotAnimation(Params);

		ButtonDeactivateTime = Time::GameTimeSeconds + ButtonDuration;
		ButtonMesh.SetMaterial(0, ActiveMat);

		//Hi John, I had to to some stuff to make it more consistent since the launch impulse from the grapple point was overriding these impulses. Yell at me if needed //Zodka
		Player.BlockCapabilities(PlayerGrappleTags::GrappleLaunch, this);
		Player.ResetMovement(true);
		FVector Impulse = Player.ActorUpVector * VerticalImpulseAmount;
		Impulse += (ImpulseDirection.ForwardVector * ForwardImpulseAmount);
		Player.AddMovementImpulse(Impulse);
		Print("Impulse " + Impulse);

		Player.UnblockCapabilities(PlayerGrappleTags::GrappleLaunch, this);

		Player.PlayCameraShake(CameraShake, this);
		Player.PlayForceFeedback(ForceFeedback, false, true, this);
		BP_ButtonPushedOn();

		if (!bOneShot)
			SetActorTickEnabled(true);
		
		FOnButtonGrappleImpactParams ButtonParams;
		ButtonParams.Location = ActorLocation;
		UButtonGrapplePointEffectHandler::Trigger_OnButtonGrappleImpact(this, ButtonParams);

		if(ButtonActivatedEvent != nullptr)
		{
			AudioComponent::PostFireForget(ButtonActivatedEvent, AudioEventParams);
		}

		OnButtonPressed.Broadcast();
	}

	void SetPermaOn()
	{
		ButtonMesh.SetMaterial(0, ActiveMat);
		SetActorTickEnabled(false);		
	}

	UFUNCTION(BlueprintEvent)
	void BP_ButtonPushedOn() {}

	UFUNCTION(BlueprintEvent)
	void BP_ButtonPushedOff() {}

	UFUNCTION()
	bool IsButtonActive()
	{
		return Time::GameTimeSeconds < ButtonDeactivateTime;
	}
	
	UFUNCTION()
	void EnableGrapplePoint(AHazePlayerCharacter Player)
	{
		if (DisablePlayers.Contains(Player))
		{
			GrappleLaunchPoint.GrappleLaunchPoint.EnableForPlayer(Player, this);
			DisablePlayers.Remove(Player);
		}

		ButtonMesh.SetMaterial(0, InactiveMat);
	}
}