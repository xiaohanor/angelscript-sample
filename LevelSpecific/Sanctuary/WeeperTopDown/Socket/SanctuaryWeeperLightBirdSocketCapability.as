class USanctuaryWeeperLightBirdSocketCapability : UInteractionCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	ASanctuaryWeeperLightBird LightBird;
	ASanctuaryWeeperLightBirdSocket Socket;

	bool bIsIlluminating;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);

		LightBird = USanctuaryWeeperLightBirdUserComponent::Get(Player).LightBird;
		Socket = Cast<ASanctuaryWeeperLightBirdSocket>(Params.Interaction.Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		if(bIsIlluminating)
		{
			Socket.OnDeactivated.Broadcast(LightBird);
			bIsIlluminating = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(IsActioning(ActionNames::PrimaryLevelAbility) || IsActioning(ActionNames::SecondaryLevelAbility))
		{
			if(bIsIlluminating)
				return;
			
			Socket.OnActivated.Broadcast(LightBird);
			bIsIlluminating = true;

		}
		else
		{
			if(!bIsIlluminating)
				return;

			Socket.OnDeactivated.Broadcast(LightBird);
			bIsIlluminating = false;
		}
		


				
	}


	
}