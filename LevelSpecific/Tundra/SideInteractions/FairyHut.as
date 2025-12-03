UCLASS(Abstract)
class AFairyHut : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UTundraPlayerSnowMonkeyGroundSlamResponseComponent SlamComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UTundraShapeshiftingInteractionComponent InteractComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent NiagaraComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent DoorFrame;

	UPROPERTY(DefaultComponent, Attach = DoorFrame)
	USceneComponent DoorRotateRoot;

	UPROPERTY(DefaultComponent, Attach = DoorRotateRoot)
	UStaticMeshComponent DoorMeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeCameraComponent DoorCam;

	UPROPERTY(EditDefaultsOnly, Category = "Animation")
	FHazePlaySlotAnimationParams AnimParamsEnter;

	UPROPERTY(EditDefaultsOnly, Category = "Animation")
	FHazePlaySlotAnimationParams AnimParamsExit;

	UPROPERTY(EditDefaultsOnly, Category = "Animation")
	FHazePlaySlotAnimationParams AnimParamsExitOutside;

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSpringArmSettingsDataAsset InsideCamSettings;

	UPROPERTY(EditDefaultsOnly)
	UTundraPlayerFairySettings InsideFairySettings;

	UPROPERTY(EditDefaultsOnly)
	UPlayerFloorMotionSettings InsideFairyWalkSettings;

	UPROPERTY(EditAnywhere)
	AFairyHutFireplace FairyHutFireplace;

	UPROPERTY(EditInstanceOnly)
	ATundraShapeshiftingOneShotInteractionActor ExitInteract;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> CamShake;

	AHazePlayerCharacter InteractingPlayer;

	default TickGroup = ETickingGroup::TG_PrePhysics;
	float TickActiveTimer = 0;
	private bool bIsInside = false;

	UFUNCTION(BlueprintPure)
	bool IsZoeInside() const
	{
		return bIsInside;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractComp.OnInteractionStarted.AddUFunction(this, n"OnInteractStarted");
		InteractComp.OnInteractionStopped.AddUFunction(this, n"OnInteractStopped");
		FairyHutFireplace.OnFireLit.AddUFunction(this, n"OnFireLit");
		SlamComp.OnGroundSlam.AddUFunction(this, n"OnSlam");
		ExitInteract.OnOneShotActivated.AddUFunction(this, n"OnExitInteractStarted");
		InteractComp.AddMutuallyExclusiveInteraction(ExitInteract.Interaction);

		SetActorTickEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (TickActiveTimer > SMALL_NUMBER)
			if (InteractingPlayer != nullptr && InteractingPlayer.Mesh.CanRequestLocomotion())
				InteractingPlayer.Mesh.RequestLocomotion(n"Movement", this);

		TickActiveTimer += DeltaSeconds;
	}

	UFUNCTION()
	private void OnExitInteractStarted(AHazePlayerCharacter Player, ATundraShapeshiftingOneShotInteractionActor Interaction)
	{
		if (InteractingPlayer != nullptr)
			return;

		SetActorTickEnabled(true);
		TickActiveTimer = 0;

		BP_OnExitInteracted();

		InteractingPlayer = Player;

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);

		auto ShapeShift = UTundraPlayerShapeshiftingComponent::Get(Player);
		UHazeSkeletalMeshComponentBase FairyMesh = ShapeShift.GetMeshForShapeType(ETundraShapeshiftShape::Small);
		FairyMesh.PlaySlotAnimation(AnimParamsExit);
	}

	/**
	 * Will be called from Blueprint when the teleport happens
	 */
	UFUNCTION(BlueprintCallable)
	void OnExitTeleportActor()
	{
		auto ShapeShift = UTundraPlayerShapeshiftingComponent::Get(InteractingPlayer);
		UHazeSkeletalMeshComponentBase FairyMesh = ShapeShift.GetMeshForShapeType(ETundraShapeshiftShape::Small);
		FairyMesh.PlaySlotAnimation(
			FHazeAnimationDelegate(),
			FHazeAnimationDelegate(this, n"OnExitAnimationFinished"),
			AnimParamsExitOutside);
	}

	UFUNCTION()
	void OnExitAnimationFinished()
	{
		InteractingPlayer.UnblockCapabilities(CapabilityTags::Movement, this);
		InteractingPlayer.UnblockCapabilities(CapabilityTags::GameplayAction, this);

		InteractingPlayer = nullptr;

		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintCallable)
	void ClearHutSettings(AHazePlayerCharacter Player)
	{
		Player.UnblockCapabilities(TundraShapeshiftingTags::ShapeshiftingInput, this);
		Player.UnblockCapabilities(CapabilityTags::Outline, this);
		Player.UnblockCapabilities(CapabilityTags::OtherPlayerIndicator, this);
		Player.OtherPlayer.UnblockCapabilities(CapabilityTags::OtherPlayerIndicator, this);
		Player.UnblockCapabilities(n"Sprint", this);
		Player.UnblockCapabilities(CapabilityTags::FindOtherPlayer, this);

		Player.ClearCameraSettingsByInstigator(this);

		Player.ClearSettingsByInstigator(this);
		bIsInside = false;

		SetSmallShapeShadowProxyEnabled(Player, true);
	}

	UFUNCTION()
	private void OnSlam(ETundraPlayerSnowMonkeyGroundSlamType GroundSlamType, FVector PlayerLocation)
	{
		Game::GetZoe().PlayWorldCameraShake(CamShake, this, FairyHutFireplace.ActorCenterLocation, 1000, 1000);

		UFairyHutEventHandler::Trigger_MonkeySlamHut(this);
		FairyHutFireplace.FairyHutSlammed();
	}

	UFUNCTION(BlueprintEvent)
	private void OnFireLit()
	{
	}

	UFUNCTION()
	private void OnInteractStopped(UInteractionComponent InteractionComponent,
						   AHazePlayerCharacter Player)
	{
		auto ShapeShift = UTundraPlayerShapeshiftingComponent::Get(Player);
		ShapeShift.GetMeshForShapeType(ETundraShapeshiftShape::Small).StopAllSlotAnimations();

		Player.BlockCapabilities(TundraShapeshiftingTags::ShapeshiftingInput, this);
		Player.BlockCapabilities(CapabilityTags::Outline, this);
		Player.BlockCapabilities(n"Sprint", this);
		Player.BlockCapabilities(CapabilityTags::FindOtherPlayer, this);

		Player.ApplyCameraSettings(InsideCamSettings, 0, this, EHazeCameraPriority::High);

		Player.ApplySettings(InsideFairySettings, this);
		Player.ApplySettings(InsideFairyWalkSettings, this);

		SetSmallShapeShadowProxyEnabled(Player, false);

		Player.DeactivateCamera(DoorCam, 0.0);
		bIsInside = true;
	}

	UFUNCTION()
	private void OnInteractStarted(UInteractionComponent InteractionComponent,
						   AHazePlayerCharacter Player)
	{
		auto ShapeShift = UTundraPlayerShapeshiftingComponent::Get(Player);
		ShapeShift.GetMeshForShapeType(ETundraShapeshiftShape::Small).PlaySlotAnimation(AnimParamsEnter);

		Player.BlockCapabilities(CapabilityTags::OtherPlayerIndicator, this);
		Player.OtherPlayer.BlockCapabilities(CapabilityTags::OtherPlayerIndicator, this);

		Player.ActivateCamera(DoorCam, 3.0, this);

		BP_OnInteracted();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnInteracted()
	{
		UFairyHutEventHandler::Trigger_DoorOpen(this);
	}

	UFUNCTION(BlueprintCallable)
	void BP_EventHandlerDoorClose() // ;)
	{
		UFairyHutEventHandler::Trigger_DoorClose(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnExitInteracted()
	{
		UFairyHutEventHandler::Trigger_DoorOpen(this);
	}

	void SetSmallShapeShadowProxyEnabled(AHazePlayerCharacter Player, bool bEnabled)
	{
		auto ShapeShift = UTundraPlayerShapeshiftingComponent::Get(Player);
		if (ShapeShift != nullptr)
		{
			UHazeSkeletalMeshComponentBase SmallShapeMesh = ShapeShift.GetMeshForShapeType(ETundraShapeshiftShape::Small);
			if (SmallShapeMesh != nullptr)
				SmallShapeMesh.SetUseShadowProxyMesh(bEnabled);
		}
	}
};
