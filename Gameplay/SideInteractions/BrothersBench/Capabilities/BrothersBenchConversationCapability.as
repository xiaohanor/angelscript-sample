struct FBrothersBenchConversationDeactivateParams
{
	AHazePlayerCharacter AbortedByPlayer = nullptr;
};

class UBrothersBenchConversationCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ABrothersBench BrothersBench;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BrothersBench = Cast<ABrothersBench>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!BrothersBench.bStartConversation)
			return false;

		// We can't start the conversation a second time
		if(BrothersBench.bHasStartedConversation)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FBrothersBenchConversationDeactivateParams& Params) const
	{
		for(auto Player : Game::Players)
		{
			if(!BrothersBench.PlayerData[Player].IsSitting())
			{
				Params.AbortedByPlayer = Player;
				return true;
			}
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		BrothersBench.bHasStartedConversation = true;

		UBrothersBenchEventHandler::Trigger_OnConversationStarted(BrothersBench);
		Print("Conversation Started");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FBrothersBenchConversationDeactivateParams Params)
	{
		BrothersBench.bHasEndedConversation = true;

		if(Params.AbortedByPlayer != nullptr)
		{
			FBrothersBenchOnConversationAbortedEventData EventData;
			EventData.AbortedByPlayer = Params.AbortedByPlayer;
			UBrothersBenchEventHandler::Trigger_OnConversationAborted(BrothersBench, EventData);
			Print(f"Conversation Aborted by {Params.AbortedByPlayer}");
		}
	}
};