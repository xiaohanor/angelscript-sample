struct FFlyingCarOfficeAssistedJump
{
	FFlyingCarOfficeAssistedJumpSettings Settings;
	FTransform WorldTarget;

	bool bValid = false;

	FFlyingCarOfficeAssistedJump(AHazeActor Owner, FFlyingCarOfficeAssistedJumpSettings JumpSettings)
	{
		Settings = JumpSettings;
		WorldTarget = Settings.Target * Owner.ActorTransform;

		bValid = true;
	}
}

struct FFlyingCarOfficeAssistedJumpSettings
{
	UPROPERTY(NotEditable)
	FTransform Target;

	UPROPERTY()
	FVector2D Dimensions = FVector2D(1000, 1000);

	UPROPERTY()
	bool bRequiresManualJump;
}

class AFlyingCarOfficeAssistedJumpTrigger : AHazeActor
{
	default TickGroup = ETickingGroup::TG_HazeInput;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UFlyingCarOfficeAssistedJumpTriggerVisualizerComponent VisualizerComponent;
#endif

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFlyingCarOfficeAssistedJumpMovablePlayerTriggerComponent PlayerTriggerComponent;
	default PlayerTriggerComponent.Settings = Settings;

	UPROPERTY(EditInstanceOnly, Meta = (MakeEditWidget))
	FTransform Target;

	UPROPERTY(EditInstanceOnly, Meta = (ShowOnlyInnerProperties))
	FFlyingCarOfficeAssistedJumpSettings Settings;

	AHazePlayerCharacter PilotPlayer = nullptr;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);

		Settings.Target = Target;
		PlayerTriggerComponent.Settings = Settings;
		PlayerTriggerComponent.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
		PlayerTriggerComponent.OnPlayerLeave.AddUFunction(this, n"OnPlayerLeave");
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		USkylineFlyingCarPilotComponent PilotComponent = USkylineFlyingCarPilotComponent::Get(Player);
		if (PilotComponent == nullptr)
			return;

		UFlyingCarOfficeAssistedJumpComponent AssistedJumpComponent = UFlyingCarOfficeAssistedJumpComponent::Get(PilotComponent.Car);
		if (AssistedJumpComponent == nullptr)
			return;

		if (Settings.bRequiresManualJump)
		{
			PilotPlayer = Player;
			SetActorTickEnabled(true);

			AssistedJumpComponent.bWaitingForInput = true;
		}
		else
		{
			// Apply and deactivate
			AssistedJumpComponent.ApplyJump(FFlyingCarOfficeAssistedJump(this, Settings));
			Deactivate();
		}
	}

	UFUNCTION()
	private void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		Deactivate();
	}	

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (Settings.bRequiresManualJump)
		{
			if (PilotPlayer == nullptr)
				return;

			USkylineFlyingCarPilotComponent PilotComponent = USkylineFlyingCarPilotComponent::Get(PilotPlayer);
			if (PilotComponent == nullptr)
				return;

			UFlyingCarOfficeAssistedJumpComponent AssistedJumpComponent = UFlyingCarOfficeAssistedJumpComponent::Get(PilotComponent.Car);
			if (AssistedJumpComponent == nullptr)
				return;

			if (PilotComponent.Car.bWasJumpActionStarted)
			{
				AssistedJumpComponent.ApplyJump(FFlyingCarOfficeAssistedJump(this, Settings));
				AssistedJumpComponent.bWaitingForInput = false;
				Deactivate();
			}
		}
	}

	void Deactivate()
	{
		PilotPlayer = nullptr;
		SetActorTickEnabled(false);
		PlayerTriggerComponent.DisableTrigger(this);
	}
}

class UFlyingCarOfficeAssistedJumpTriggerVisualizerComponent : UActorComponent {};
class UFlyingCarOfficeAssistedJumpComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UFlyingCarOfficeAssistedJumpTriggerVisualizerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		AFlyingCarOfficeAssistedJumpTrigger JumpTrigger = Cast<AFlyingCarOfficeAssistedJumpTrigger>(Component.Owner);
		if (JumpTrigger == nullptr)
			return;

		FTransform WorldTarget = JumpTrigger.Target * JumpTrigger.ActorTransform;
		FVector Bounds = FVector(0, JumpTrigger.Settings.Dimensions.X, JumpTrigger.Settings.Dimensions.Y);
		DrawWireBox(WorldTarget.Location, Bounds, WorldTarget.Rotation, FLinearColor::Purple + FLinearColor::Green * 0.2, 20);
	}
}