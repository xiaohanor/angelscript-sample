class ASkylineFlipChair : AHazeActor
{
	default TickGroup = ETickingGroup::TG_PrePhysics;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractComp;
	default InteractComp.bPlayerCanCancelInteraction = false;
	default InteractComp.bIsImmediateTrigger = true;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CameraSetting;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase ChairMesh;

	UPROPERTY(EditAnywhere)
	FHazePlaySlotAnimationParams AnimFallPlayer;

	UPROPERTY(EditAnywhere)
	FHazePlaySlotAnimationParams AnimFallChair;

	UPROPERTY(EditDefaultsOnly)
	float DelayUntilHitGround = 2.3;
	
	UPROPERTY(EditDefaultsOnly)
	float DelayRequestMovement = 5;

	bool bFallen = false;

	AHazePlayerCharacter InteractingPlayer;
	float TimeInteractionStarted;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractComp.OnInteractionStarted.AddUFunction(this, n"HandleInteractionStarted");

		SetActorTickEnabled(false);

		ChairMesh.SetRenderStatic(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Time::GetGameTimeSince(TimeInteractionStarted) > DelayUntilHitGround)
		{
			if (!bFallen)
				OnHitGround();
			
			if (Time::GetGameTimeSince(TimeInteractionStarted) > DelayRequestMovement)
			{
				if (InteractingPlayer != nullptr && InteractingPlayer.Mesh.CanRequestLocomotion())
					InteractingPlayer.Mesh.RequestLocomotion(n"Movement", this);
			}
		}
	}

	private void OnHitGround()
	{
		bFallen = true;

		FSkylineFlipChairEffectEventParams Params;
		Params.Player = InteractingPlayer;
		USkylineFlipChairEffectEventHandler::Trigger_HitGround(this, Params);
		InteractingPlayer.DamagePlayerHealth(0.1);
		AddActorCollisionBlock(this);
		
	}

	UFUNCTION()
	private void HandleInteractionStarted(UInteractionComponent InteractionComponent,
								  AHazePlayerCharacter Player)
	{
		if (InteractingPlayer != nullptr)
			return;

		ChairMesh.SetRenderStatic(false);

		TimeInteractionStarted = Time::GameTimeSeconds;

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);

		SetActorTickEnabled(true);

		InteractionComponent.Disable(this);

		Player.ApplyCameraSettings(CameraSetting, 4.0, this);

		Player.PlaySlotAnimation(FHazeAnimationDelegate(),
								 FHazeAnimationDelegate(this, n"OnAnimationFinished"),
								 AnimFallPlayer);

		ChairMesh.PlaySlotAnimation(AnimFallChair);

		InteractingPlayer = Player;
	}

	UFUNCTION()
	void OnAnimationFinished()
	{
		SetActorTickEnabled(false);
		ChairMesh.SetComponentTickEnabled(false);

		InteractingPlayer.UnblockCapabilities(CapabilityTags::Movement, this);
		InteractingPlayer.UnblockCapabilities(CapabilityTags::GameplayAction, this);

		InteractingPlayer.ClearCameraSettingsByInstigator(this);
		InteractingPlayer = nullptr;
		
	}
};