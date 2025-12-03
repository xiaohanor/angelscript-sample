class UShuttleLiftVizualiser : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UShuttleLiftVisualiserComponent;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        auto ShuttleLift = Cast<AShuttleLift>(Component.Owner);

        if (ShuttleLift == nullptr)
            return;		
		float HeightOffset = ShuttleLift.MaxHeight / ShuttleLift.ZDivisions;

		for(int i = 1; i <= ShuttleLift.ZDivisions; i++)
		{
			DrawWireSphere(ShuttleLift.ActorLocation + FVector(0,0,HeightOffset * i), 500.0, FLinearColor::Green, 5.0);
		}
    }
}

class UShuttleLiftVisualiserComponent : UActorComponent
{
	
}

class AShuttleLift : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeCameraComponent CameraComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent LeftInteraction;
	default LeftInteraction.bPlayerCanCancelInteraction = false;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent RightInteraction;
	default RightInteraction.bPlayerCanCancelInteraction = false;

	UPROPERTY(DefaultComponent)
	UShuttleLiftVisualiserComponent VisualizerComp;

	UPROPERTY(EditAnywhere)
	AShuttleLiftEnergyPendulum ShuttleLiftEnergyLeft;

	UPROPERTY(EditAnywhere)
	AShuttleLiftEnergyPendulum ShuttleLiftEnergyRight;

	float ZMinClamp;
	float ZMaxClamp;
	float MaxHeight = 8000.0;
	int ZDivisions = 8;

	float HeightOffset;
	float HeightTarget;

	TPerPlayer<bool> bPlayerInteracting;
	TPerPlayer<bool> bPlayersFired;
	TPerPlayer<float> ValidTimer;
	float Cooldown = 0.5;

	FVector TEMPStartLoc;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HeightOffset = MaxHeight / ZDivisions;
		LeftInteraction.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
		RightInteraction.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
		LeftInteraction.OnInteractionStopped.AddUFunction(this, n"OnInteractionStopped");
		RightInteraction.OnInteractionStopped.AddUFunction(this, n"OnInteractionStopped");

		ZMinClamp = ActorLocation.Z;
		HeightTarget = ActorLocation.Z;
		ZMaxClamp = MaxHeight + ZMinClamp;


		TEMPStartLoc = ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ValidTimer[0] -= DeltaSeconds;
		ValidTimer[1] -= DeltaSeconds;
		ValidTimer[0] = Math::Clamp(ValidTimer[0], 0, Cooldown);
		ValidTimer[1] = Math::Clamp(ValidTimer[1], 0, Cooldown);

		if (ValidTimer[0] > 0 && ValidTimer[1] > 0)
		{
			if (ShuttleLiftEnergyLeft.HasSafeProgress())
			{
				HeightTarget += HeightOffset;
				ValidTimer[0] = 0;
				ValidTimer[1] = 0;
			}
		}

		// for(int i = 1; i <= ZDivisions; i++)
		// {
		// 	Debug::DrawDebugSphere(TEMPStartLoc + FVector(0,0,HeightOffset * i), 300.0, 12, FLinearColor::Green, 10);
		// }

		FVector TargetLoc = FVector(ActorLocation.X, ActorLocation.Y, HeightTarget);
		ActorLocation = Math::VInterpConstantTo(ActorLocation, TargetLoc, DeltaSeconds, HeightOffset);
	}

	UFUNCTION()
	private void OnInteractionStarted(UInteractionComponent InteractionComponent,
	                                  AHazePlayerCharacter Player)
	{
		auto UserComp = UShuttleLiftPlayerComponent::Get(Player);
		UserComp.Lift = this;
		UserComp.bIsActive = true;
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		Player.ActivateCamera(CameraComp, 2.5, this, EHazeCameraPriority::VeryHigh);
		bPlayerInteracting[Player] = true;

		if (InteractionComponent == LeftInteraction)
		{
			UserComp.Pendulum = ShuttleLiftEnergyLeft;
		}
		else
		{
			UserComp.Pendulum = ShuttleLiftEnergyRight;
		}

		if (bPlayerInteracting[0] && bPlayerInteracting[1])
		{
			Game::Mio.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen);
			ShuttleLiftEnergyLeft.StartPendulum();
			ShuttleLiftEnergyRight.StartPendulum();
		}
	
		Player.AttachToActor(this, NAME_None, EAttachmentRule::KeepWorld);
	}

	UFUNCTION()
	private void OnInteractionStopped(UInteractionComponent InteractionComponent,
	                                  AHazePlayerCharacter Player)
	{
		auto UserComp = UShuttleLiftPlayerComponent::Get(Player);
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		UserComp.bIsActive = false;
		Player.DeactivateCamera(CameraComp, 2.5);
		bPlayerInteracting[Player] = false;
		Game::Mio.ClearViewSizeOverride(this);

		Player.DetachFromActor(EDetachmentRule::KeepWorld);
	}

	void FireLiftMovement(AHazePlayerCharacter Player)
	{
		ValidTimer[Player] = Cooldown;
	}

	// void UpdateMovement(float Amount)
	// {
	// 	ActorLocation += FVector(0,0,Amount);
	// 	ActorLocation = FVector(ActorLocation.X, ActorLocation.Y, Math::Clamp(ActorLocation.Z, ZMinClamp, ZMaxClamp)); 
	// }
};