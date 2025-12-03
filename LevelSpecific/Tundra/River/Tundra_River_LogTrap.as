class ATundra_River_LogTrap : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotationScene;

	UPROPERTY(DefaultComponent, Attach = FPCone)
	UStaticMeshComponent SM_Log;

	UPROPERTY(DefaultComponent, Attach = RotationScene)
	UCableComponent CableComp;

	UPROPERTY(DefaultComponent, Attach = SM_Log)
	UBoxComponent DeathVolume;
	default DeathVolume.CollisionProfileName = n"TriggerOnlyPlayer";

	UPROPERTY(DefaultComponent, Attach = RotationScene)
	UScenepointComponent ScenePoint;

	UPROPERTY(DefaultComponent, Attach = RotationScene)
	UFauxPhysicsTranslateComponent FPTranslate;

	UPROPERTY(DefaultComponent, Attach = FPTranslate)
	UFauxPhysicsConeRotateComponent FPCone;

	UPROPERTY(EditInstanceOnly)
	APerchSpline PerchSplineActor;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent FPPlayerWeight;

	bool bDeathVolumeDisableCheck = false;
	bool bPOIDisableCheck = false;

	AHazePlayerCharacter TriggeringPlayer;
	
	UPROPERTY()
	FHazeTimeLike SwingAnimation;	
	default SwingAnimation.Duration = 8;
	default SwingAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default SwingAnimation.Curve.AddDefaultKey(2.0, 1.5);
	default SwingAnimation.Curve.AddDefaultKey(3.5, 0.83);
	default SwingAnimation.Curve.AddDefaultKey(5.5, 1.15);
	default SwingAnimation.Curve.AddDefaultKey(7, 0.95);
	default SwingAnimation.Curve.AddDefaultKey(8.0, 1.0);

	UPROPERTY(EditInstanceOnly)
	float TargetAngle;

	UPROPERTY(EditInstanceOnly)
	float Length;

	UPROPERTY(EditInstanceOnly)
	APlayerTrigger TriggerBox;

	UPROPERTY(EditInstanceOnly)
	bool bTriggerPOI;

	bool bHasTriggered = false;

	UFUNCTION(CallInEditor)
	void InitCableLength()
	{
		FPTranslate.SetRelativeLocation(FVector(Length, 0, 0));
		CableComp.CableLength = Length/2;
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(PerchSplineActor != nullptr)
		{
			PerchSplineActor.AttachToComponent(FPCone);
			PerchSplineActor.SetActorRelativeLocation(FVector(200,0,45));
			PerchSplineActor.SetActorRelativeRotation(FRotator(0, 90, 0));
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DeathVolume.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		if(TriggerBox != nullptr)
			TriggerBox.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnterTrigger");
		DeathVolume.OnComponentBeginOverlap.AddUFunction(this, n"OnPlayerEnterDeathVolume");
		SwingAnimation.BindUpdate(this, n"TL_SwingAnimation");
		SwingAnimation.BindFinished(this, n"TL_SwingAnimationFinished");
		SwingAnimation.PlayRate = 1.4;

		// Perch spline setup
		if(PerchSplineActor != nullptr)
		{
			PerchSplineActor.AttachToComponent(FPCone);
			PerchSplineActor.SetActorRelativeLocation(FVector(200,0,45));
			PerchSplineActor.SetActorRelativeRotation(FRotator(0, 90, 0));
		}
	}

	UFUNCTION()
	void OnPlayerEnterDeathVolume(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, const FHitResult&in HitResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		Player.KillPlayer();
		UTundra_River_LogTrap_EffectHandler::Trigger_KilledAPlayer(this);
	}

	UFUNCTION()
	void TL_SwingAnimation(float CurveValue)
	{
		RotationScene.SetRelativeRotation(FRotator(CurveValue*TargetAngle, 0, 0));
		if(bDeathVolumeDisableCheck && SwingAnimation.GetPosition() > 3.0/8.0)
		{
			DeathVolume.SetCollisionEnabled(ECollisionEnabled::NoCollision);
			bDeathVolumeDisableCheck = false;
		}
		if(bPOIDisableCheck && bTriggerPOI && SwingAnimation.GetPosition() > 1.0/8.0)
		{
			TriggeringPlayer.ClearPointOfInterestByInstigator(this);
		}
	}

	UFUNCTION()
	void TL_SwingAnimationFinished()
	{
		UTundra_River_LogTrap_EffectHandler::Trigger_StopMoving(this);
	}

	UFUNCTION()
	void OnPlayerEnterTrigger(AHazePlayerCharacter Player)
	{
		if(bHasTriggered)
			return;

		TriggeringPlayer = Player;

		bHasTriggered = true;

		if(bTriggerPOI)
		{
			FApplyPointOfInterestSettings POISetting;
			POISetting.Duration = 1;
			POISetting.TurnScaling = FRotator(0.05, 0.05, 0.05);
			FHazePointOfInterestFocusTargetInfo POIFocus;
			POIFocus.SetFocusToComponent(ScenePoint);
			Player.ApplyPointOfInterest(this, POIFocus, POISetting, 0.5, EHazeCameraPriority::Low);
		}

		DeathVolume.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
		SwingAnimation.PlayFromStart();
		UTundra_River_LogTrap_EffectHandler::Trigger_StartMoving(this);
		bDeathVolumeDisableCheck = true;
		bPOIDisableCheck = true;
	}
};