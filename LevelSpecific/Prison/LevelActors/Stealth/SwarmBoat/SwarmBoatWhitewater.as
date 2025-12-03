class ASwarmBoatWhitewater : AHazeActor
{
	default SetTickGroup(ETickingGroup::TG_PrePhysics);

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USwarmBoatWhitewaterMovableTriggerComponent MovableTriggerComponent;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshComponent;
	default MeshComponent.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY()
	UNiagaraComponent WaterFlowNiagaraComponent;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComponent;

	UPROPERTY(DefaultComponent)
	private UArrowComponent MoveDirection;
	default MoveDirection.SetWorldRotation(ActorUpVector.Rotation());
	default MoveDirection.ArrowSize = 10.0;
	default MoveDirection.ArrowColor = FLinearColor::LucBlue;


	UPROPERTY(EditAnywhere)
	bool bStartActive = true;

	UPROPERTY(EditAnywhere, Category = "Movement")
	float ImpulseMagnitude = 700.0;

	UPROPERTY(EditAnywhere, Category = "Camera")
	TSubclassOf<UCameraShakeBase> CameraShakeClass;

	UPROPERTY(Transient)
	AHazePlayerCharacter ActivePlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
		MovableTriggerComponent.DisableTriggerForPlayer(Drone::MagnetDronePlayer, this);

		WaterFlowNiagaraComponent = UNiagaraComponent::Get(this, n"vfx_WaterflowNiagaraComponent");

		MovableTriggerComponent.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
		MovableTriggerComponent.OnPlayerLeave.AddUFunction(this, n"OnPlayerLeave");

		if (!bStartActive)
			StopStream();
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		ActivePlayer = Player;
		SetActorTickEnabled(true);

		if (CameraShakeClass.IsValid())
			Player.PlayCameraShake(CameraShakeClass, this);

		SpeedEffect::RequestSpeedEffect(Player, 0.2, this, EInstigatePriority::Low);
	}

	UFUNCTION()
	private void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		ActivePlayer = nullptr;
		SetActorTickEnabled(false);

		Player.StopCameraShakeByInstigator(this);

		SpeedEffect::ClearSpeedEffect(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (ActivePlayer == nullptr)
			return;

		FVector Impulse = MoveDirection.ForwardVector.ConstrainToPlane(ActivePlayer.MovementWorldUp) * ImpulseMagnitude * DeltaTime * 10.0;
		ActivePlayer.AddMovementImpulse(Impulse, n"SwarmBoatWhitewater");

		FHazeFrameForceFeedback FFF;
		FFF.LeftMotor = Math::Abs(Math::PerlinNoise1D(GameTimeSinceCreation)) * 0.2;
		FFF.RightMotor = Math::Abs(Math::PerlinNoise1D(GameTimeSinceCreation + 1.86)) * 0.2;
		ActivePlayer.SetFrameForceFeedback(FFF);
	}

	UFUNCTION()
	void StartStream()
	{
		MovableTriggerComponent.EnableTrigger(this);
		MeshComponent.SetHiddenInGame(false);

		if (WaterFlowNiagaraComponent != nullptr)
			WaterFlowNiagaraComponent.Activate();
	}

	UFUNCTION()
	void StopStream()
	{
		MovableTriggerComponent.DisableTrigger(this);
		MeshComponent.SetHiddenInGame(true);

		if (WaterFlowNiagaraComponent != nullptr)
			WaterFlowNiagaraComponent.Deactivate();
	}
}