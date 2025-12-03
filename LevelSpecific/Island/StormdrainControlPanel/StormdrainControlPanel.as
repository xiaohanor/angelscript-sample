event void FStormdrainRotationTickSignature(float Rotation);



UCLASS(Abstract)
class AStormdrainControlPanel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent HologramRotationSyncComponent;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Table;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Base;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent HologramRoot;
	float HologramScale = 0.0;
	float HologramScaleUpSpeed = 2.0;

	UPROPERTY(EditInstanceOnly)
	AActor StormdrainFan;

	UPROPERTY(DefaultComponent, Attach = HologramRoot)
	USceneComponent Hologram_RotatingScene;
	float HologramRotation = 0.0;
	float HologramRotationSpeed = 0.0;
	float HologramMaxRotationSpeed = 25.0;
	float HologramRotationAcceleration = 10.0;

	UPROPERTY()
	FStormdrainRotationTickSignature StormdrainRotationTick;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeCameraComponent Camera;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractionComponent;
	default InteractionComponent.bPlayerCanCancelInteraction = true;
	default InteractionComponent.InteractionCapability = n"StormdrainControlPanelCapability";
	default InteractionComponent.MovementSettings = FMoveToParams::SmoothTeleport();

	default PrimaryActorTick.bStartWithTickEnabled = false;


	UPROPERTY()
	FTutorialPrompt TutorialPrompt;
	default TutorialPrompt.DisplayType = ETutorialPromptDisplay::LeftStick_LeftRight;

	AHazePlayerCharacter InteractingPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UpdateHologramScale();
		ActorTickEnabled = false;
		//TutorialPrompt.DisplayType = ETutorialPromptDisplay::LeftStick_LeftRight;
		//TutorialPrompt.Text = FText::FromName(n"Spin up the Stormdrain");
		InteractionComponent.OnInteractionStarted.AddUFunction(this, n"InteractionStarted");
		InteractionComponent.OnInteractionStopped.AddUFunction(this, n"InteractionStopped");
	}

	UFUNCTION()
	private void InteractionStarted(UInteractionComponent OneShotInteraction, AHazePlayerCharacter Player)
	{
		Player.ActivateCamera(Camera, 1.0, this, EHazeCameraPriority::High);
		Player.ShowTutorialPrompt(TutorialPrompt, this);
		ActorTickEnabled = true;
		InteractingPlayer = Player;
	}

	UFUNCTION()
	private void InteractionStopped(UInteractionComponent OneShotInteraction, AHazePlayerCharacter Player)
	{
		Player.DeactivateCamera(Camera, 1.0);
		Player.RemoveTutorialPromptByInstigator(this);
		InteractingPlayer = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		//Print("Table is ticking", 0.0);
		if(InteractingPlayer != nullptr && HologramScale < 1)
		{
			HologramScale = Math::Min(HologramScale + HologramScaleUpSpeed * DeltaSeconds, 1.0);
			UpdateHologramScale();
		}
		else if(InteractingPlayer == nullptr && HologramScale > 0)
		{
			HologramScale = Math::Max(HologramScale - HologramScaleUpSpeed * DeltaSeconds, 0.0);
			if(HologramScale <= 0.01)
			{
				HologramScale = 0.0;
				ActorTickEnabled = false;
			}
			UpdateHologramScale();
		}

		if(HologramRotationSyncComponent.HasControl())
		{
			HologramRotationSyncComponent.Value = HologramRotation;
		}

		else
		{
			HologramRotation = HologramRotationSyncComponent.Value;
			Hologram_RotatingScene.SetRelativeRotation(FRotator(0.0, HologramRotation, 0.0));
			StormdrainFan.SetActorRotation(FRotator(0,HologramRotation,0));
		}
	}

	void RotationInput(FVector2D Input, float DeltaSeconds)
	{
		HologramRotationSpeed = Math::FInterpConstantTo(HologramRotationSpeed, Input.X*HologramMaxRotationSpeed, DeltaSeconds, HologramRotationAcceleration);
		HologramRotation += HologramRotationSpeed * DeltaSeconds;
		HologramRotation = Math::Wrap(HologramRotation, 0.0, 360.0);
		Hologram_RotatingScene.SetRelativeRotation(FRotator(0.0, HologramRotation, 0.0));
		//Print("Input", 0.0);
		StormdrainFan.SetActorRotation(FRotator(0,HologramRotation,0));
	}

	void UpdateHologramScale()
	{
		HologramRoot.SetRelativeScale3D(FVector(HologramScale,HologramScale,HologramScale));
	}
}