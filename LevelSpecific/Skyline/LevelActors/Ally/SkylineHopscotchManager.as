class ASkylineHopscotchManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent BillboardComp;

	UPROPERTY(EditInstanceOnly)
	TArray<APerchPointActor> PerchPoints;

	UPROPERTY(EditAnywhere)
	UAnimSequence HopScotchCompletedAnim;

	UPROPERTY(EditAnywhere)
	UAnimSequence HopScotchCrushedAnim;

	UPROPERTY(EditAnywhere)
	UAnimSequence HopScotchPerfectAnim;

	TPerPlayer<int> PerchIndex;

	TPerPlayer<float> StartTime;

	TPerPlayer<float> FinishedTimeStamp;

	TPerPlayer<bool> bCelebrating;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (auto PerchPoint : PerchPoints)
		{
			PerchPoint.OnPlayerStartedPerchingEvent.AddUFunction(this, n"HandleStartedPerch");
			PerchPoint.OnPlayerStoppedPerchingEvent.AddUFunction(this, n"HandleStoppedPerch");
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (auto Player : Game::Players)
		{
			if (bCelebrating[Player] && FinishedTimeStamp[Player] + 1.0 < Time::GameTimeSeconds)
			{
				bCelebrating[Player] = false;
				Player.UnblockCapabilities(PlayerPerchPointTags::PerchPointJumpOff, this);
			}
		}
	}

	UFUNCTION()
	private void HandleStoppedPerch(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		Player.StopAllSlotAnimations();
	}

	UFUNCTION()
	private void HandleStartedPerch(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		if (PerchPoint.Owner == PerchPoints[1])
		{
			PerchIndex[Player] = 2;
			USkylineHopscotchEffectEventHandler::Trigger_LandOnCorrectTile(this, GetEventParams(Player));
		}
		else if (PerchPoint.Owner == PerchPoints[PerchIndex[Player]])
		{
			PerchIndex[Player] ++;
			USkylineHopscotchEffectEventHandler::Trigger_LandOnCorrectTile(this, GetEventParams(Player));
		}
		else
		{
			PerchIndex[Player] = 0;
			USkylineHopscotchEffectEventHandler::Trigger_LandOnIncorrectTile(this, GetEventParams(Player));
		}

		if (PerchIndex[Player] == 1)
		{
			StartTime[Player] = Time::GameTimeSeconds;
			USkylineHopscotchEffectEventHandler::Trigger_LandOnCorrectTile(this, GetEventParams(Player));
		}

		if (PerchIndex[Player] >= PerchPoints.Num())
			HopScotchCompleted(Player);

		PrintToScreen("Index = " + PerchIndex[Player], 5.0);
	}

	private void HopScotchCompleted(AHazePlayerCharacter Player)
	{
		PerchIndex[Player] = 0;
		float Duration = (Time::GameTimeSeconds - StartTime[Player]);

		if (Duration < 4.0)
		{
			Player.PlaySlotAnimation(Animation = HopScotchPerfectAnim, bLoop = true, PlayRate = 0.25);
			USkylineHopscotchEffectEventHandler::Trigger_CompletedFast(this, GetEventParams(Player));
		}
		else if (Duration < 5.0)
		{
			Player.PlaySlotAnimation(Animation = HopScotchCrushedAnim, bLoop = true);
			USkylineHopscotchEffectEventHandler::Trigger_CompletedMedium(this, GetEventParams(Player));
		}
		else
		{
			Player.PlaySlotAnimation(Animation = HopScotchCompletedAnim);
			USkylineHopscotchEffectEventHandler::Trigger_CompletedSlow(this, GetEventParams(Player));

		}

		bCelebrating[Player] = true;
		FinishedTimeStamp[Player] = Time::GameTimeSeconds;

		Player.BlockCapabilities(PlayerPerchPointTags::PerchPointJumpOff, this);

		PrintToScreenScaled("Duration = " + Duration, 5.0);
	}

	FSkylineHopscotchEffectEventParams GetEventParams(AHazePlayerCharacter Player)
	{
		FSkylineHopscotchEffectEventParams Params;
		Params.Player = Player;
		return Params;
	}
};

UCLASS(Abstract)
class USkylineHopscotchEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LandOnCorrectTile(FSkylineHopscotchEffectEventParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LandOnIncorrectTile(FSkylineHopscotchEffectEventParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CompletedSlow(FSkylineHopscotchEffectEventParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CompletedMedium(FSkylineHopscotchEffectEventParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CompletedFast(FSkylineHopscotchEffectEventParams Params) {}
}

struct FSkylineHopscotchEffectEventParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}