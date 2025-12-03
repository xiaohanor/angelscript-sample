
class UAnimInstanceSwarmBotGroup : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Retracted;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Idle;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData HoverParachute;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData HoverDive;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData BoatPropeller;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FHazeSwarmBotAnimNodeDataInput SwarmBotInputData;

	UPlayerSwarmDroneComponent SwarmDroneComponent;
	const int BotCount = 50;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		SwarmDroneComponent = UPlayerSwarmDroneComponent::Get(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		SwarmBotInputData.SwarmBotAnimData.SetNum(SwarmDrone::TotalBotCount);
		for (int i = 0; i < SwarmDrone::TotalBotCount; i++)
		{
			FHazeSwarmBotAnimData AnimData;
			AnimData.BotIndex = i;
			SwarmBotInputData.SwarmBotAnimData[i] = AnimData;
		}
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		// Update in-game drone
		if (SwarmDroneComponent != nullptr)
		{
			// Update gameplay data
			for (auto SwarmBot : SwarmDroneComponent.SwarmBots)
			{
				SwarmBotInputData.SwarmBotAnimData[SwarmBot.Id] = SwarmBot.GroupSkelMeshAnimData;
			}
		}

		// Update cutscene drone
		ACutsceneSwarmDrone CutsceneSwarmDrone = Cast<ACutsceneSwarmDrone>(HazeOwningActor);
		if (CutsceneSwarmDrone != nullptr)
		{
			for (int i = 0; i < CutsceneSwarmDrone.SwarmBots.Num(); i++)
			{
				FCutsceneSwarmBotData& SwarmBot = CutsceneSwarmDrone.SwarmBots[i];
				SwarmBot.AnimData.Transform = SwarmBot.RelativeTransform * CutsceneSwarmDrone.SwarmGroupMeshComponent.WorldTransform;
				SwarmBotInputData.SwarmBotAnimData[i] = SwarmBot.AnimData;
			}
		}
	}
}
