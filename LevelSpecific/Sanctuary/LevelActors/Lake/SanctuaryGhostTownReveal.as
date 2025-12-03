class ASanctuaryGhostTownReveal : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	APlayerTrigger Trigger;

	UPROPERTY(EditInstanceOnly)
	FDarkPortalInvestigationDestination DarkPortalInvestigationDestination;

	UPROPERTY(EditInstanceOnly)
	FLightBirdInvestigationDestination LightBirdInvestigationDestination;

	bool bMioDoOnce = true;
	bool bZoeDoOnce = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Trigger.OnPlayerEnter.AddUFunction(this, n"HandleOnPlayerEnter");

		LightBirdInvestigationDestination.OverrideSpeed = 1000.0;
		DarkPortalInvestigationDestination.OverrideSpeed = 1000.0;

		DarkPortalInvestigationDestination.Type = EDarkPortalInvestigationType::Flyby;
		LightBirdInvestigationDestination.Type = ELightBirdInvestigationType::Flyby;

		DarkPortalInvestigationDestination.TargetComp = Root;
		LightBirdInvestigationDestination.TargetComp = Root;
	}

	UFUNCTION()
	private void HandleOnPlayerEnter(AHazePlayerCharacter EnteringPlayer)
	{
			if (EnteringPlayer == Game::Zoe && bZoeDoOnce)
			{
				bZoeDoOnce = false;
				DarkPortalCompanion::DarkPortalInvestigate(DarkPortalInvestigationDestination,this);
			}

			if (EnteringPlayer == Game::Mio && bMioDoOnce)
			{
				bMioDoOnce = false;
				LightBirdCompanion::LightBirdInvestigate(LightBirdInvestigationDestination,this);
			}
	}
};