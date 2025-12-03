event void FIslandShieldotronPlayerTriggerOnBothPlayersLeftEvent();
class AIslandShieldotronSettingsPlayerTrigger : APlayerTrigger
{
	FIslandShieldotronPlayerTriggerOnBothPlayersLeftEvent OnBothPlayersLeft;
	TPerPlayer<bool> PlayersWithin;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActor;

	UPROPERTY(EditAnywhere)
	UHazeComposableSettings Settings;

	UPROPERTY(EditAnywhere)
	TArray<UHazeComposableSettings> AdditionalSettings;

	UPROPERTY(EditAnywhere)
	EHazeSettingsPriority Priority = EHazeSettingsPriority::Gameplay;

	TArray<AHazeActor> ListenerActors;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
		OnPlayerLeave.AddUFunction(this, n"OnPlayerLeave");
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		PlayersWithin[Player] = true;

		for (AHazeActor Listener : ListenerActors)
		{
			ApplySettings(Listener);
		}
	}

	UFUNCTION()
	private void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		PlayersWithin[Player] = false;
		if (!PlayersWithin[Player.GetOtherPlayer()])
		{
			OnBothPlayersLeft.Broadcast();
			for (int I = ListenerActors.Num() - 1; I >= 0; I--)
			{
				AHazeActor Listener = ListenerActors[I];
				ClearSettings(Listener);

				// Remove any dead listeners
				if (Listener.IsActorDisabled())
					RemoveListenerActor(Listener);
			}
		}
	}

	// Can hook this up in BP
	UFUNCTION()
	void AddListenerActor(AHazeActor Actor)
	{
		ListenerActors.AddUnique(Actor);
	}
	
	UFUNCTION()
	void RemoveListenerActor(AHazeActor Actor)
	{
		ListenerActors.Remove(Actor);
	}

	bool IsWhithinShape(AHazeActor Actor)
	{
		return this.EncompassesPoint(Actor.ActorCenterLocation);
	}

	UFUNCTION()
	private void ApplySettings(AHazeActor Actor)
	{
		Actor.ApplySettings(Settings, this, Priority);
		for (UHazeComposableSettings MoreSettings : AdditionalSettings)
		{
			Actor.ApplySettings(MoreSettings, this, Priority);
		}
	}

	UFUNCTION()
	private void ClearSettings(AHazeActor Actor)
	{
		Actor.ClearSettingsByInstigator(this);
	}
}