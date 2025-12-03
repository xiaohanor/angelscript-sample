event void FOnTipOver();

UCLASS(Abstract)
class AOilRigTransportShip : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent TransportRoot;

	UPROPERTY(DefaultComponent, Attach = TransportRoot)
	USceneComponent TiltRoot;

	UPROPERTY(DefaultComponent, Attach = TiltRoot)
	UFauxPhysicsConeRotateComponent WobbleRoot;

	UPROPERTY(DefaultComponent, Attach = WobbleRoot)
	USceneComponent FrontThrusterRoot;

	UPROPERTY(DefaultComponent, Attach = WobbleRoot)
	USceneComponent BackThrusterRoot;

	UPROPERTY(DefaultComponent, Attach = WobbleRoot)
	USceneComponent ContainerDropRoot;

	UPROPERTY(DefaultComponent, Attach = TiltRoot)
	UPlayerInheritMovementComponent InheritMovementComp;

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSettingsDataAsset CamSettings;

	UPROPERTY(EditInstanceOnly)
	ASplineActor FollowSpline;
	UHazeSplineComponent SplineComp;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike StartUpTimeLike;
	FVector StartUpStartLocation;
	FVector StartUpTargetLocation;
	float StartUpTargetHeight = 1600.0;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike TipOverTimeLike;
	float TipTiltStartRot = 0.0;

	UPROPERTY()
	FOnTipOver OnTipOver;

	float MaxSpeed = 16000.0;
	float CurrentSpeed = 0.0;

	float SplineDist = 0.0;

	bool bStartingUp = false;
	bool bMoving = false;
	bool bContainerDropped = false;

	FRotator PreviousRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplineComp = FollowSpline.Spline;

		StartUpTimeLike.BindUpdate(this, n"UpdateStartUp");
		StartUpTimeLike.BindFinished(this, n"FinishStartUp");

		TipOverTimeLike.BindUpdate(this, n"UpdateTipOver");
		TipOverTimeLike.BindFinished(this, n"FinishTipOver");
	}

	UFUNCTION()
	void StartUp()
	{
		StartUpStartLocation = ActorLocation;
		StartUpTargetLocation = StartUpStartLocation;
		StartUpTargetLocation.Z += StartUpTargetHeight;
		StartUpTimeLike.PlayFromStart();

		BP_StartUp();

		UOilRigTransportShipEffectEventEventHandler::Trigger_StartUp(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_StartUp() {}

	UFUNCTION()
	private void UpdateStartUp(float CurValue)
	{
		FVector Loc = Math::Lerp(StartUpStartLocation, StartUpTargetLocation, CurValue);
		SetActorLocation(Loc);
	}

	UFUNCTION()
	private void FinishStartUp()
	{
		StartMoving();
	}

	UFUNCTION()
	void StartMoving()
	{
		bMoving = true;

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			Player.ApplyCameraSettings(CamSettings, 5.0, this, EHazeCameraPriority::High);
		}

		BP_StartMoving();

		UOilRigTransportShipEffectEventEventHandler::Trigger_StartMoving(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_StartMoving() {}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bMoving)
			return;

		CurrentSpeed = Math::Clamp(CurrentSpeed + 1500.0 * DeltaTime, 0.0, MaxSpeed);
		SplineDist += CurrentSpeed * DeltaTime;

		FVector Loc = SplineComp.GetWorldLocationAtSplineDistance(SplineDist);

		FRotator Rot = SplineComp.GetWorldRotationAtSplineDistance(SplineDist).Rotator();
		Rot.Pitch = 0.0;
		Rot.Roll = 0.0;

		SetActorLocationAndRotation(Loc, Rot);

		float YawDif = ActorRotation.Yaw - PreviousRotation.Yaw;
		float TargetTilt = Math::GetMappedRangeValueClamped(FVector2D(-0.5, 0.5), FVector2D(-5.0, 5.0), YawDif);
		float Tilt = Math::FInterpTo(TiltRoot.RelativeRotation.Roll, TargetTilt, DeltaTime, 1.0);
		TiltRoot.SetRelativeRotation(FRotator(0.0, 0.0, Tilt));

		PreviousRotation = ActorRotation;
	}

	UFUNCTION()
	void StartGettingAttacked()
	{
		UOilRigTransportShipEffectEventEventHandler::Trigger_StartGettingAttacked(this);
	}

	UFUNCTION(DevFunction)
	void DropContainer()
	{
		if (bContainerDropped)
			return;

		bContainerDropped = true;
		BP_DropContainer();

		UOilRigTransportShipEffectEventEventHandler::Trigger_DropContainer(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_DropContainer() {}

	UFUNCTION()
	void TipOver()
	{
		bMoving = false;

		InheritMovementComp.DisableTrigger(this);

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			Player.ResetMovement();
			Player.ClearCameraSettingsByInstigator(this);
		}

		TipTiltStartRot = TiltRoot.RelativeRotation.Roll;

		TipOverTimeLike.PlayFromStart();
		OnTipOver.Broadcast();

		UOilRigTransportShipEffectEventEventHandler::Trigger_TipOver(this);
	}

	UFUNCTION(BlueprintPure)
	float GetPlayerRelativeLocationAlpha(AHazePlayerCharacter Player)
	{
		FVector RelativeLoc = ActorTransform.InverseTransformPosition(Player.ActorLocation);
		return Math::GetMappedRangeValueClamped(FVector2D(-1200.0, 1200), FVector2D(0.0, 1.0), RelativeLoc.Y);
	}

	UFUNCTION()
	private void UpdateTipOver(float CurValue)
	{
		float Rot = Math::Lerp(0.0, -179.0, CurValue);
		TransportRoot.SetRelativeRotation(FRotator(0.0, 0.0, Rot));

		float Tilt = Math::Lerp(TipTiltStartRot, 0.0, Math::Min(CurValue * 2.0, 1.0));
		TiltRoot.SetRelativeRotation(FRotator(0.0, 0.0, Tilt));
	}

	UFUNCTION()
	private void FinishTipOver()
	{
		AddActorDisable(this);
	}

	UFUNCTION()
	void PlayerIgnoreShipCollision(AHazePlayerCharacter Player)
	{
		UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Player);
		MoveComp.AddMovementIgnoresActor(this, this);
		Player.ResetMovement(true, FVector::UpVector, false);
	}
}

class UOilRigTransportShipEffectEventEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void StartUp() {}
	UFUNCTION(BlueprintEvent)
	void StartMoving() {}
	UFUNCTION(BlueprintEvent)
	void StartGettingAttacked() {}
	UFUNCTION(BlueprintEvent)
	void DropContainer() {}
	UFUNCTION(BlueprintEvent)
	void TipOver() {}
}