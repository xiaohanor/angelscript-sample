

class UHazeVoxTriggerActions : UScriptActorMenuExtension
{
	default ExtensionPoint = n"ActorViewOptions";
	default SupportedClasses.Add(AVoxPlayerTrigger);

	/**
	 * Replace with a VoxAdvancedPlayerTrigger, matching properties as much as possible
	 */
	UFUNCTION(CallInEditor, Meta = (EditorIcon = "HazeVox.VoxSpeaker"))
	void ReplaceWithAdvancedTrigger()
	{
		TArray<AVoxPlayerTrigger> ToReplace;

		// Filter out actors to replace
		TArray<AActor> SelectedActors = Editor::SelectedActors;
		for (AActor Actor : SelectedActors)
		{
			AVoxPlayerTrigger VoxTrigger = Cast<AVoxPlayerTrigger>(Actor);
			if (IsValid(VoxTrigger))
			{
				ToReplace.Add(VoxTrigger);
			}
		}

		TArray<AActor> NewActors;
		Editor::ReplaceActors(ToReplace, AVoxAdvancedPlayerTrigger, NewActors);

		TArray<FString> MissmatchBoundsTriggers;

		for (AActor NewActor : NewActors)
		{
			AVoxAdvancedPlayerTrigger NewTrigger = Cast<AVoxAdvancedPlayerTrigger>(NewActor);
			NewTrigger.Modify();

			AVoxPlayerTrigger OldTrigger = nullptr;
			for (AVoxPlayerTrigger PossibleOldActor : ToReplace)
			{
				if (PossibleOldActor.ActorGuid == NewTrigger.ActorGuid)
				{
					OldTrigger = PossibleOldActor;
					break;
				}
			}

			if (OldTrigger == nullptr)
				continue;

			if (NewTrigger.GetBounds() != OldTrigger.GetBounds())
			{
				MissmatchBoundsTriggers.Add(NewTrigger.GetActorNameOrLabel());
			}

			NewTrigger.bTriggerForMio = OldTrigger.bTriggerForMio;
			NewTrigger.bTriggerForZoe = OldTrigger.bTriggerForZoe;
			NewTrigger.bTriggerLocally = OldTrigger.bTriggerLocally;

			UVoxTriggerComponent OldTriggerComponent = OldTrigger.VoxTriggerComponent;
			UVoxAdvancedPlayerTriggerComponent NewTriggerComponent = NewTrigger.VoxAdvancedTriggerComponent;

			NewTriggerComponent.VoxAsset = OldTriggerComponent.VoxAsset;
			NewTriggerComponent.MioVoxAsset = OldTriggerComponent.MioVoxAsset;
			NewTriggerComponent.ZoeVoxAsset = OldTriggerComponent.ZoeVoxAsset;
			for (auto ActorRef : OldTriggerComponent.Actors)
			{
				NewTriggerComponent.Actors.Add(ActorRef);
			}

			NewTriggerComponent.DelayBeforePlaying = OldTriggerComponent.DelayBeforePlaying;

			switch (OldTrigger.TriggerType)
			{
				case EVoxPlayerTriggerType::AnyPlayersInside:
					NewTrigger.TriggerCondition = EVoxPlayerAdvancedTriggerCondition::AnyPlayersInside;
					NewTrigger.WhoPlays = EVoxPlayerAdvancedTriggerWhoPlays::FirstInside;
					break;

				case EVoxPlayerTriggerType::BothPlayersInside:
					NewTrigger.TriggerCondition = EVoxPlayerAdvancedTriggerCondition::BothPlayersInside;
					NewTrigger.WhoPlays = EVoxPlayerAdvancedTriggerWhoPlays::FirstInside;
					break;

				case EVoxPlayerTriggerType::OnlyOnePlayerInside:
					NewTrigger.TriggerCondition = EVoxPlayerAdvancedTriggerCondition::OnlyOnePlayerInside;
					NewTrigger.WhoPlays = EVoxPlayerAdvancedTriggerWhoPlays::FirstInside;
					break;

				case EVoxPlayerTriggerType::BothPlayersOnlyFirstInsidePlays:
					NewTrigger.TriggerCondition = EVoxPlayerAdvancedTriggerCondition::BothPlayersInside;
					NewTrigger.WhoPlays = EVoxPlayerAdvancedTriggerWhoPlays::FirstInside;
					break;

				case EVoxPlayerTriggerType::BothPlayersOnlyLastInsidePlays:
					NewTrigger.TriggerCondition = EVoxPlayerAdvancedTriggerCondition::BothPlayersInside;
					NewTrigger.WhoPlays = EVoxPlayerAdvancedTriggerWhoPlays::LastInside;
					break;

				case EVoxPlayerTriggerType::VisitedByBothPlayersFirstInsidePlays:
					NewTrigger.TriggerCondition = EVoxPlayerAdvancedTriggerCondition::VisitedByBothPlayers;
					NewTrigger.WhoPlays = EVoxPlayerAdvancedTriggerWhoPlays::FirstInside;
					break;

				case EVoxPlayerTriggerType::VisitedByBothPlayersLastInsidePlays:
					NewTrigger.TriggerCondition = EVoxPlayerAdvancedTriggerCondition::VisitedByBothPlayers;
					NewTrigger.WhoPlays = EVoxPlayerAdvancedTriggerWhoPlays::LastInside;
					break;
			}

			if (OldTriggerComponent.TimeInTrigger > 0.0)
			{
				NewTriggerComponent.TriggerType = EVoxAdvancedPlayerTriggerType::TimeInTrigger;
				NewTriggerComponent.TimeInTrigger = OldTriggerComponent.TimeInTrigger;
				NewTriggerComponent.bResetTimeInTriggerOnLeave = OldTriggerComponent.bResetDelayOnLeave;
			}

			if (OldTriggerComponent.bRepeatForever == true)
			{
				NewTriggerComponent.RepeatMode = EVoxAdvancedPlayerTriggerRepeat::WhileActive;
				NewTriggerComponent.NumRepeats = 0;
				if (OldTriggerComponent.TimeInTrigger > 0.0)
				{
					NewTriggerComponent.TimeBetweenRepeats = OldTriggerComponent.TimeInTrigger;
				}
			}
			else if (OldTriggerComponent.MaxTriggerCount > 1)
			{
				NewTriggerComponent.RepeatMode = EVoxAdvancedPlayerTriggerRepeat::WhileActive;
				NewTriggerComponent.NumRepeats = OldTriggerComponent.MaxTriggerCount;
				if (OldTriggerComponent.TimeInTrigger > 0.0)
				{
					NewTriggerComponent.TimeBetweenRepeats = OldTriggerComponent.TimeInTrigger;
				}
			}
		}

		if (MissmatchBoundsTriggers.Num() > 0)
		{
			FString Message = "VoxAdvancedPlayerTrigger(s) has different bounds from trigger being replaced.\nAny custom brush edits will be lost.\n";

			for (const FString& Trigger : MissmatchBoundsTriggers)
			{
				Message += f"\n{Trigger}";
			}

			Editor::MessageDialog(EAppMsgType::Ok, FText::FromString(Message));
		}
	}
}
