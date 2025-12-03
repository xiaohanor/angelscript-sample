class ASkylineGravityBikeElevatorsTrigger : APlayerTrigger
{
	default Shape::SetVolumeBrushColor(this, FLinearColor::DPink);

	UPROPERTY(DefaultComponent)
	USkylineGravityBikeElevatorsTriggerVisualComponent VisualComp;

	UPROPERTY()
	bool bActivated = false;

	UPROPERTY(EditInstanceOnly)
	bool bDeactivator = false;

	UPROPERTY(EditInstanceOnly)
	TArray<ASkylineGravityBikeElevator> ElevatorsToActivateArray;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnPlayerEnter.AddUFunction(this, n"HandlePlayerEnter");
	}

	UFUNCTION()
	private void HandlePlayerEnter(AHazePlayerCharacter Player)
	{
		if (!bActivated)
			Activate();
	}

	UFUNCTION()
	void Activate()
	{
		bActivated = true;

		for (auto Elevator : ElevatorsToActivateArray)
		{
			if (!bDeactivator)
				Elevator.Activate();
			else
				Elevator.Deactivate();
		}
	}
}

class USkylineGravityBikeElevatorsTriggerVisualComponent : UActorComponent
{
	UPROPERTY(EditInstanceOnly)
	bool bDrawArrow = true;
}

class USkylineGravityBikeElevatorsTriggerVisualComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USkylineGravityBikeElevatorsTriggerVisualComponent;

	UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
	{
		ASkylineGravityBikeElevatorsTrigger Trigger = Cast<ASkylineGravityBikeElevatorsTrigger>(Component.Owner);
		if(Trigger == nullptr)
			return;

		for (auto Elevator : Trigger.ElevatorsToActivateArray)
		{
			if (Trigger.bDeactivator)
				DrawArrow(Trigger.ActorLocation, Elevator.ActorLocation, FLinearColor::Red, 300.0, 50.0);
			else
				DrawArrow(Trigger.ActorLocation, Elevator.ActorLocation, FLinearColor::Green, 300.0, 50.0);
		}
	}
}