event void FonDangerDisabled();
event void FOndangerStarted();

class AMeltdownUnderwaterDangerInteraction : AOneShotInteractionActor
{
	default PrimaryActorTick.TickGroup = ETickingGroup::TG_PostPhysics;
	
	default Interaction.bStartDisabled = true;
	default Interaction.UsableByPlayers = EHazeSelectPlayer::Zoe;

	UPROPERTY(EditAnywhere)
	bool bAutoStartDanger = true;
	UPROPERTY(EditAnywhere)
	float InteractionUsableRange = 1500.0;
	UPROPERTY(EditInstanceOnly)
	AMeltdownUnderwaterManager Manager;

	bool bIsDangerous = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		Interaction.OnInteractionStarted.AddUFunction(this, n"OnStartInteraction");

		if (bAutoStartDanger)
			StartDanger();
	}

	UFUNCTION(BlueprintEvent)
	void BP_StartDanger() {}
	UFUNCTION(BlueprintEvent)
	void BP_StopDanger() {}
	
	UPROPERTY()
	FonDangerDisabled DangerAvoided;

	UPROPERTY()
	FOndangerStarted DangerStarted;


	UFUNCTION()
	void StartDanger()
	{
		if (bIsDangerous)
			return;

		Interaction.EnableAfterStartDisabled();
		bIsDangerous = true;
		BP_StartDanger();
		DangerStarted.Broadcast();
	}

	UFUNCTION()
	private void OnStartInteraction(UInteractionComponent InteractionComponent,
	                                AHazePlayerCharacter Player)
	{
		Interaction.Disable(n"DangerAvoided");
		bIsDangerous = false;
		BP_StopDanger();
		DangerAvoided.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		auto Player = Game::Zoe;
		
		if (bIsDangerous)
		{
			FVector DisplayPos;
			bool bOnScreen = Manager.ProjectSeethrough_InsideToOutside(
				ActorLocation, true, DisplayPos
			);

			if (!bOnScreen || ActorLocation.Distance(Player.OtherPlayer.ActorLocation) > InteractionUsableRange)
			{
				Interaction.Disable(n"Offscreen");
			}
			else
			{
				DisplayPos -= Interaction.WidgetVisualOffset;
				Interaction.Enable(n"Offscreen");
				Interaction.WorldLocation = DisplayPos;
			}
		}
	}
};