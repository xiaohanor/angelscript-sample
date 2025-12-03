class ASanctuaryRecallCompanionTrigger : APlayerTrigger
{
		UPROPERTY(EditAnywhere)
	EInstigatePriority Priority = EInstigatePriority::Override;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnPlayerEnter.AddUFunction(this, n"HandlePlayerEnter");
	}

	UFUNCTION()
	private void HandlePlayerEnter(AHazePlayerCharacter Player)
	{
		if (Player == Game::Mio)
		{
			auto UserComp = ULightBirdUserComponent::Get(Game::Mio);

			if(UserComp.Companion.CompanionComp.State == ELightBirdCompanionState::Follow)
			{
				return;
			}
			//UserComp.Companion.CompanionComp.State = ELightBirdCompanionState::LaunchExit;
			UserComp.Hover();
		}
			
		if (Player == Game::Zoe)
		{
			auto UserComp = UDarkPortalUserComponent::Get(Game::Zoe);
			if(UserComp.Companion.CompanionComp.State == EDarkPortalCompanionState::Follow)
			{
				return;
			}

			//UserComp.Companion.CompanionComp.State = EDarkPortalCompanionState::PortalExit;
			UserComp.Portal.InstantRecall();

			}
			
	}

	UFUNCTION(BlueprintCallable)
	void CallRecallBothCompanions()
	{
		auto UserComp = UDarkPortalUserComponent::Get(Game::Zoe);
		UserComp.Portal.InstantRecall();

	}

};
