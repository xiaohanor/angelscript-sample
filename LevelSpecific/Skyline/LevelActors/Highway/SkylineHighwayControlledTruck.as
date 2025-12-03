class USkylineHighwayControlledTruckInputCapability : UHazeCapability
{   
	ASkylineHighwayControlledTruck Truck;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
		Truck = Cast<ASkylineHighwayControlledTruck>(Owner);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() const
    {
		if (Truck.ControllingPlayer == nullptr)
			return false;

        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() const
    {
		if (Truck.ControllingPlayer == nullptr)
			return true;

        return false;
    }

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
        CapabilityInput::LinkActorToPlayerInput(Truck, Truck.ControllingPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		auto Input = GetAttributeVector2D(AttributeVectorNames::MovementRaw);

		Truck.LocalInput = Owner.ActorTransform.TransformVectorNoScale(FVector(Input.X, Input.Y, 0.0));
	}
}

class ASkylineHighwayControlledTruck : AHazeActor
{
	FSplinePosition TargetSplinePosition;

	UPROPERTY(DefaultComponent, RootComponent)
	UFauxPhysicsSplineFollowComponent SplineFollowComp;
	default SplineFollowComp.bFollowRotation = false;
	default SplineFollowComp.Friction = 1.5;
	default SplineFollowComp.SplineBoundBounce = 0.25;
	default SplineFollowComp.NetworkMode = EFauxPhysicsSplineFollowNetworkMode::SyncedFromMioControl;

	UPROPERTY(DefaultComponent, Attach = SplineFollowComp)
	UFauxPhysicsAxisRotateComponent AxisRotateComp;
	default AxisRotateComp.Friction = 3.0;
	default AxisRotateComp.ForceScalar = 0.05;
	default AxisRotateComp.LocalRotationAxis = FVector::ForwardVector;
	default AxisRotateComp.SpringStrength = 10.0;
	default AxisRotateComp.NetworkMode = EFauxPhysicsAxisRotateNetworkMode::SyncedFromMioControl;

	UPROPERTY(DefaultComponent, Attach = AxisRotateComp)
	USkylineHighwayFloatingComponent FloatingComp;
	default FloatingComp.bReattachChildrenToThis = true;
	default FloatingComp.bUseLocationOffset = false;
	default FloatingComp.bUseImpostorMeshesAtDistance = false;
	default FloatingComp.bDisableCollisionAtDistance = false;

	UPROPERTY(DefaultComponent, Attach = FloatingComp)
	UThreeShotInteractionComponent InteractionComp;

	UPROPERTY(DefaultComponent, Attach = FloatingComp)
	UHazeSkeletalMeshComponentBase Driver;

	UPROPERTY(DefaultComponent, Attach = FloatingComp)
	UStaticMeshComponent DriverWindow;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineHighwayControlledTruckInputCapability");

	UPROPERTY(EditAnywhere)
	FTutorialPrompt TutorialPrompt;

	UPROPERTY(EditAnywhere)
	UAnimSequence FirstEnterAnimation;
	TPerPlayer<UAnimSequence> EnterAnimation;

	UPROPERTY(EditAnywhere)
	UBlendSpace SteeringBS;

	UPROPERTY(EditAnywhere)
	float Force = 1500.0;

	UPROPERTY(EditAnywhere)
	UAnimSequence DriverAnimation;

	UPROPERTY(EditAnywhere)
	AHazeCameraActor FirstEnterCamera;

	UPROPERTY(EditAnywhere)
	AHazeCameraActor TruckCamera;

	AHazePlayerCharacter ControllingPlayer;

	FVector LocalInput;

	bool bHasEntered = false;
	float CurrentSplineDistance = 0.0;
	FHazeAcceleratedFloat AccFloat;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComp.DisableForPlayer(Game::Zoe, this);

		// Setup Enter Animations
		for (auto Player : Game::Players)
		{
			EnterAnimation[Player] = InteractionComp.ThreeShotSettings[Player].EnterAnimation;
			InteractionComp.ThreeShotSettings[Player].EnterAnimation = FirstEnterAnimation;
		}

		InteractionComp.OnInteractionStarted.AddUFunction(this, n"HandleInteractionStarted");
		InteractionComp.OnInteractionStopped.AddUFunction(this, n"HandleInteractionStopped");
		InteractionComp.OnEnterBlendingOut.AddUFunction(this, n"HandleEnterBlendingOut");
		InteractionComp.OnCancelPressed.AddUFunction(this, n"HandleCancelPressed");
	
		TargetSplinePosition = SplineFollowComp.SplinePosition;
		CurrentSplineDistance = TargetSplinePosition.CurrentSplineDistance;
		SplineFollowComp.ForceScalar = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (ControllingPlayer != nullptr)
		{
			bool bAtEnd = !TargetSplinePosition.Move(-LocalInput.Y * Force * DeltaSeconds);
			AccFloat.AccelerateTo(TargetSplinePosition.CurrentSplineDistance, 4.0, DeltaSeconds);
			CurrentSplineDistance = AccFloat.Value;
			SplineFollowComp.SplinePosition = SplineFollowComp.SplinePosition.CurrentSpline.GetSplinePositionAtSplineDistance(CurrentSplineDistance);

//			FauxPhysics::ApplyFauxForceToActorAt(this, ActorLocation + ActorUpVector, ActorRightVector * -AccFloat.Velocity * 2.0);
			FauxPhysics::ApplyFauxForceToActorAt(this, ActorLocation + ActorUpVector, LocalInput * (bAtEnd ? 0.0 : 1.0) * 2000.0);
			ControllingPlayer.SetBlendSpaceValues(LocalInput.Y);

			float Freq = 20.0;
//			float FFDirection = Math::Clamp(SplineFollowComp.Velocity * 0.0012, -1.0, 1.0);
			float FFDirection = Math::Clamp(AccFloat.Velocity * 0.0012, -1.0, 1.0);

			FHazeFrameForceFeedback FFF;
			FFF.LeftMotor = (Math::Sin(Time::GameTimeSeconds * Freq * 2.0 * PI) + 1.0) * 0.5 * (Math::Abs(Math::Max(FFDirection, 0.0) * 0.5) + 0.01);
			FFF.RightMotor = (Math::Sin(Time::GameTimeSeconds * Freq * 2.0 * PI) + 1.0) * 0.5 * (Math::Abs(Math::Min(FFDirection, 0.0) * 0.5) + 0.01);
			ControllingPlayer.SetFrameForceFeedback(FFF);
		}
	}

	UFUNCTION()
	private void HandleInteractionStarted(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player)
	{
		if (!bHasEntered)
			Player.ActivateCamera(FirstEnterCamera, 1.5, this);
		else
			Player.ActivateCamera(FirstEnterCamera, 0.0, this);

		Player.BlockCapabilities(CapabilityTags::Death, this);

		FHazePlaySlotAnimationParams AnimationParams;
		AnimationParams.Animation = DriverAnimation;
		Driver.bPauseAnims = false;
		Driver.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(this, n"OnAnimationBlendingOut"), AnimationParams);

		if (!bHasEntered)
			Timer::SetTimer(this, n"BreakDriverWindow", 0.73);

		USkylineHighwayControlledTruckEventHandler::Trigger_OnWindowBreak(this);
	}

	UFUNCTION()
	private void OnAnimationBlendingOut()
	{
		Driver.SetHiddenInGame(true);
	}

	UFUNCTION()
	private void BreakDriverWindow()
	{
		DriverWindow.SetHiddenInGame(true);
		BP_DriverWindowBreak();
	}

	UFUNCTION()
	private void HandleInteractionStopped(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player)
	{
		Player.DeactivateCamera(FirstEnterCamera, 1.0);
		Player.UnblockCapabilities(CapabilityTags::Death, this);
	}

	UFUNCTION()
	private void HandleEnterBlendingOut(AHazePlayerCharacter Player, UThreeShotInteractionComponent Interaction)
	{
		if (!bHasEntered)
			Player.DeactivateCamera(FirstEnterCamera, 3.0);

		Player.ActivateCamera(TruckCamera, 2.0, this);

		Player.PlayBlendSpace(SteeringBS);

		bHasEntered = true;

		ControllingPlayer = Player;
		Player.ShowTutorialPromptWorldSpace(TutorialPrompt, this, FloatingComp, FVector::UpVector * -400.0, 0.0);
	}

	UFUNCTION()
	private void HandleCancelPressed(AHazePlayerCharacter Player, UThreeShotInteractionComponent Interaction)
	{
		Player.DeactivateCamera(TruckCamera);

		Player.StopBlendSpace();

		ControllingPlayer = nullptr;
		Player.RemoveTutorialPromptByInstigator(this);

		InteractionComp.ThreeShotSettings[Player].EnterAnimation = EnterAnimation[Player];
	}

	UFUNCTION(BlueprintEvent)
	void BP_DriverWindowBreak() { }
};