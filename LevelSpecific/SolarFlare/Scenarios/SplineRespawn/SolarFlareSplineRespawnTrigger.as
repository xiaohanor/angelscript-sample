asset SolarFlareSplineRespawnSheet of UHazeCapabilitySheet
{
	AddCapability(n"SolarFlareSplineRespawnCapability");
	Components.Add(USolarFlareSplineRespawnComponent);
}

asset SolarFlareSplineRespawnPlayerHealthSettings of UPlayerHealthSettings
{
	bGameOverWhenBothPlayersDead = true;
}

class ASolarFlareSplineRespawnTrigger : APlayerTrigger
{
	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;

	/** For sampling the direction the player should respawn in
	 * 	(Will default to actor right if not set) */
	UPROPERTY(EditAnywhere, Category = "Setup")
	ASplineActor RespawnSpline;

	/** If set to false, you have to call a function on this trigger to deactivate it */
	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bDeactivateWhenLeavingVolume = false;

	/** If the player should try respawning on the right side of the other player first.
	 * (Will go to the opposite side if cannot find the ground on that side) */
	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bPreferRightSideRespawn = true;

	/** How far away on either side of the other player the respawn triggers at */
	UPROPERTY(EditAnywhere, Category = "Settings")
	float RespawnDistanceToSide = 200.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	UPlayerHealthSettings HealthSettings;
	default HealthSettings = SolarFlareSplineRespawnPlayerHealthSettings;

	TPerPlayer<bool> HasStarted;

	UFUNCTION(BlueprintOverride)
	void BeginPlay() override
	{
		Super::BeginPlay();

		RequestComp.AddSheetToInitialStopped(SolarFlareSplineRespawnSheet);

		for(auto Player : Game::Players)
		{
			auto SplineRespawnComp = USolarFlareSplineRespawnComponent::Get(Player);
			SplineRespawnComp.RespawnTrigger = this;
		}
		
		OnPlayerEnter.AddUFunction(this, n"OnEnter");
		OnPlayerLeave.AddUFunction(this, n"OnLeft");
	}

	void ActivateSplineRespawn(AHazePlayerCharacter Player)
	{
		RequestComp.StartInitialSheetsAndCapabilities(Player, this);
		Player.ApplySettings(HealthSettings, this);
		HasStarted[Player] = true;
	}

	void DeactivateSplineRespawn(AHazePlayerCharacter Player)
	{
		RequestComp.StopInitialSheetsAndCapabilities(Player, this);
		Player.ClearSettingsByInstigator(this);
		HasStarted[Player] = false;
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnEnter(AHazePlayerCharacter Player)
	{
		if(HasStarted[Player])
			return;

		ActivateSplineRespawn(Player);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnLeft(AHazePlayerCharacter Player)
	{
		if(!bDeactivateWhenLeavingVolume)
			return;

		if(!HasStarted[Player])
			return;

		RequestComp.StopInitialSheetsAndCapabilities(Player, this);
		HasStarted[Player] = false;
	}

	UFUNCTION()
	void ToggleSplineRespawn(bool bActivate, EHazeSelectPlayer PlayersToToggle)
	{
		TArray<AHazePlayerCharacter> Players;
		if(PlayersToToggle == EHazeSelectPlayer::Mio)
			Players.Add(Game::Mio);
		else if(PlayersToToggle == EHazeSelectPlayer::Zoe)
			Players.Add(Game::Zoe);
		else if(PlayersToToggle == EHazeSelectPlayer::Both)
			Players.Append(Game::Players);

		for(auto Player : Players)
		{
			if(bActivate)
			{
				if(!HasStarted[Player])
				{
					ActivateSplineRespawn(Player);
				}
			}
			else
			{
				if(HasStarted[Player])
				{
					DeactivateSplineRespawn(Player);
				}
			}
		}
	}
};