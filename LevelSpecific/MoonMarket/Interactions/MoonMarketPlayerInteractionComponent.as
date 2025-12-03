class UMoonMarketPlayerInteractionComponent : UActorComponent
{
	AHazePlayerCharacter Player;
	TArray<AMoonMarketInteractableActor> CurrentInteractions;

	TArray<AMoonMarketInteractableActor> PendingInteractions;

	AMoonMarketObjectDropVolume DropVolume;
	TInstigated<AMoonMarketObjectVolume> ObjectVolumes;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		UPlayerHealthComponent::Get(Player).OnDeathTriggered.AddUFunction(this, n"OnDeath");

		if(HasControl())
			UMoonMarketThunderStruckComponent::Get(Owner).OnStruckByThunder.AddUFunction(this, n"OnStruckByThunder");
	}

	UFUNCTION()
	private void OnStruckByThunder(FMoonMarketThunderStruckData Data)
	{
		for(int i = CurrentInteractions.Num()-1; i >= 0; i--)
		{
			if(!CurrentInteractions[i].bCancelByThunder)
				continue;
		
			CrumbStopInteraction(CurrentInteractions[i]);
		}
	}

	UFUNCTION()
	void OnDeath()
	{
		TArray<AMoonMarketInteractableActor> CurrentInteractionsCopy;
		CurrentInteractionsCopy.Append(CurrentInteractions);
		
		for(int i = CurrentInteractionsCopy.Num() - 1; i >= 0; i--)
		{
			if(!CurrentInteractionsCopy[i].bCancelInteractionUponDeath)
				continue;

			CurrentInteractions[i].OnInteractionStopped(Player);

			//This can happen if the OnInteractionStopped also removes the interaction from the array (only happens with the balloons atm)
			if(i >= CurrentInteractions.Num())
				continue;

			CurrentInteractions.RemoveAt(i);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbStopAllInteractions()
	{
		for(auto Interaction : CurrentInteractions)
			Interaction.OnInteractionStopped(Player);

		CurrentInteractions.Empty();
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartNewInteraction(AMoonMarketInteractableActor NewInteraction)
	{
		if(NewInteraction == nullptr)
		{
			PrintError("Tried to start new interaction but the interaction was null");
			return;
		}

		if(CurrentInteractions.Contains(NewInteraction))
		{
			PrintError("Tried to start interaction that is already started");
			return;
		}

		if(CurrentInteractions.Num() > 0)
		{
			for(int i = CurrentInteractions.Num()-1; i >= 0; i--)
			{
				if(i >= CurrentInteractions.Num())
					continue;

				AMoonMarketInteractableActor Interaction = CurrentInteractions[i];
				bool bCompatible = NewInteraction.CompatibleInteractions.Contains(Interaction.InteractableTag) || Interaction.CompatibleInteractions.Contains(NewInteraction.InteractableTag);
				
				if(Interaction.InteractableTag == EMoonMarketInteractableTag::None)
					bCompatible = false;

				if(bCompatible)
					continue;
			
				CurrentInteractions.RemoveAt(i);
				Interaction.OnInteractionStopped(Player);
			}
		}

		CurrentInteractions.Add(NewInteraction);
		NewInteraction.StartInteractionTime = Time::GameTimeSeconds;
	}

	void StopInteraction(AMoonMarketInteractableActor InteractionToStop)
	{
		if(!CurrentInteractions.Contains(InteractionToStop))
		{
			PrintError("Stopping interaction that does not exist");
			return;
		}
		
		CurrentInteractions.Remove(InteractionToStop);
		InteractionToStop.OnInteractionStopped(Player);
	}

	UFUNCTION(CrumbFunction)
	void CrumbStopInteraction(AMoonMarketInteractableActor InteractionToStop)
	{
		StopInteraction(InteractionToStop);
	}

	UFUNCTION(CrumbFunction)
	void CrumbCancelLatestInteraction()
	{
		if(CurrentInteractions.IsEmpty())
			return;

		CurrentInteractions.Last().OnInteractionCanceled();
		StopInteraction(CurrentInteractions.Last());
	}
};