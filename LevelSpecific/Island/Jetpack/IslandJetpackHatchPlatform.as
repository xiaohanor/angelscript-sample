UCLASS(Abstract)
class AIslandJetpackHatchPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UFauxPhysicsAxisRotateComponent HatchRoot;

	UPROPERTY(DefaultComponent, Attach = HatchRoot)
	USceneComponent ShakeRoot;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBoxComponent VentBoxTrigger;

	UPROPERTY(DefaultComponent, Attach = ShakeRoot)
	UBoxComponent DeathBoxTrigger;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CamShakeFFComp;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactCallbackComp;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> ImpactCamShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ImpactFF;

	UPROPERTY(EditAnywhere, Category = "Timing")
	float DeactivatedDuration = 3.0;

	UPROPERTY(EditAnywhere, Category = "Timing")
	float ActivatedDuration = 5.0;

	UPROPERTY(EditAnywhere, Category = "Timing")
	float StartDelay = 0.0;

	UPROPERTY(EditAnywhere, Category = "Timing")
	float DeactivationAnticipationAlpha = 0.7;

	UPROPERTY(EditAnywhere)
	float VentPushStrength = 60;

	bool bActive = false;
	bool bShaking = false;
	bool bMioInside = false;
	bool bZoeInside = false;
	TArray<AHazePlayerCharacter> PlayersInExhaust;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(StartDelay < 0.01)
			StartDelay = 0.01;
		
		Timer::SetTimer(this, n"Activate", StartDelay);

		HatchRoot.OnMinConstraintHit.AddUFunction(this, n"MinConstraintHit");
		HatchRoot.OnMaxConstraintHit.AddUFunction(this, n"MaxConstraintHit");
		VentBoxTrigger.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlapBegin");
		VentBoxTrigger.OnComponentEndOverlap.AddUFunction(this, n"OnOverlapEnd");
		DeathBoxTrigger.OnComponentEndOverlap.AddUFunction(this, n"DeathTriggerOverlap");

		DeathBoxTrigger.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	UFUNCTION()
	private void OnOverlapEnd(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                          UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		
		if(Player == nullptr)
			return;

		PlayersInExhaust.RemoveSingleSwap(Player);

		if(Player.IsMio())
		{
			bMioInside = false;
		}
		else
		{
			bZoeInside = false;
		}
	}

	UFUNCTION()
	private void DeathTriggerOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                 UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		FPlayerDeathDamageParams DeathParams;
		DeathParams.bApplyStaticCamera = true;
		if(Player != nullptr)
			Player.KillPlayer(DeathParams);
	}

	UFUNCTION()
	private void OnOverlapBegin(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                            UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                            const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if(Player == nullptr)
			return;

		PlayersInExhaust.AddUnique(Player);

		if(Player.IsMio())
		{
			bMioInside = true;
		}
		else
		{
			bZoeInside = true;
		}
	}

	UFUNCTION()
	private void MinConstraintHit(float Strength)
	{
		CamShakeFFComp.ActivateCameraShakeAndForceFeedback();

		// for (AHazePlayerCharacter Player : Game::GetPlayers())
		// {
		// 	if(Player != nullptr)
		// 	{
		// 		Player.PlayWorldCameraShake(ImpactCamShake, this, ActorLocation, 1500.0, 2000.0, 1.0, 0.75);
		// 	}
		// }

		// ForceFeedback::PlayWorldForceFeedback(ImpactFF, ActorLocation, true, this, 1500.0, 500.0);
		// CrushPlayers();
	}

	UFUNCTION()
	private void MaxConstraintHit(float Strength)
	{
		CamShakeFFComp.ActivateCameraShakeAndForceFeedback();

		// for (AHazePlayerCharacter Player : Game::GetPlayers())
		// {
		// 	if(Player != nullptr)
		// 	{
		// 		Player.PlayWorldCameraShake(ImpactCamShake, this, ActorLocation, 1500.0, 2000.0, 1.0, 0.5);
		// 	}
		// }

		// ForceFeedback::PlayWorldForceFeedback(ImpactFF, ActorLocation, true, this, 1500.0, 500.0);

		// CrushPlayers();

		DeathBoxTrigger.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	UFUNCTION()
	void CrushPlayers()
	{
		TArray<AActor> OverlappedActors;
		DeathBoxTrigger.GetOverlappingActors(OverlappedActors);
		for(auto Actor : OverlappedActors)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
			if(Player != nullptr)
				Player.DamagePlayerHealth(1);
		}
	}

	UFUNCTION()
	void PushPlayers()
	{
		if(bMioInside)
		{
			Game::GetMio().AddMovementImpulse(-ActorRightVector * VentPushStrength);
		}

		if(bZoeInside)
		{
			Game::GetZoe().AddMovementImpulse(-ActorRightVector * VentPushStrength);
		}

		FIslandHatchPlatformExhaustParams Params;
		Params.BlownPlayers = PlayersInExhaust;
		UIslandJetpackHatchPlatformEffectEventHandler::Trigger_PlayerBlownAway(this, Params);
	}

	UFUNCTION(NotBlueprintCallable)
	void Activate()
	{
		bActive = true;
		BP_Activate();
		UIslandJetpackHatchPlatformEffectEventHandler::Trigger_Activate(this);

		Timer::SetTimer(this, n"Deactivate", ActivatedDuration);
		Timer::SetTimer(this, n"StartShake", ActivatedDuration * DeactivationAnticipationAlpha);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Activate() {}

	UFUNCTION(NotBlueprintCallable)
	void Deactivate()
	{
		bActive = false;
		bShaking = false;
		ShakeRoot.RelativeRotation = FRotator(0, 0, 0);
		BP_Deactivate();
		UIslandJetpackHatchPlatformEffectEventHandler::Trigger_Deactivate(this);

		Timer::SetTimer(this, n"Activate", DeactivatedDuration);

		DeathBoxTrigger.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Deactivate() {}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bActive)
		{
			HatchRoot.ApplyAngularForce(-20.0);
			PushPlayers();
		}

		if(bShaking)
		{
			float SineRotate = Math::Sin(Time::GetGameTimeSeconds() * 50);
			ShakeRoot.RelativeRotation = FRotator(0, 0, 0.7) * SineRotate;
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void StartShake()
	{
		bShaking = true;

		FIslandHatchPlatformShakeParams Params;
		Params.ImpactingPlayers = ImpactCallbackComp.GetImpactingPlayers();

		UIslandJetpackHatchPlatformEffectEventHandler::Trigger_StartShake(this, Params);
	}
}

struct FIslandHatchPlatformShakeParams
{
	UPROPERTY()
	TArray<AHazePlayerCharacter> ImpactingPlayers;
}

struct FIslandHatchPlatformExhaustParams
{
	UPROPERTY()
	TArray<AHazePlayerCharacter> BlownPlayers;
}

class UIslandJetpackHatchPlatformEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void Activate() {}
	UFUNCTION(BlueprintEvent)
	void Deactivate() {}
	UFUNCTION(BlueprintEvent)
	void StartShake(FIslandHatchPlatformShakeParams Params) {}
	UFUNCTION(BlueprintEvent)
	void PlayerBlownAway(FIslandHatchPlatformExhaustParams Params) {}
};
