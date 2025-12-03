event void FHardModeTriggeredGameOverSignature();

class ASkylineBallBossHardModeManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY()
	TSubclassOf<USkylineBallBossHardModeWidget> HardModeWidgetClass;

	USkylineBallBossHardModeWidget HardModeWidget;

	UPROPERTY()
	UPlayerHealthSettings DefaultHPSettings;

	UPROPERTY()
	UPlayerHealthSettings GameOverHPSettings;

	UPROPERTY()
	FHardModeTriggeredGameOverSignature OnTriggeredGameOver;

	bool bHardModeEnabled = false;

	int SharedHP = 3;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (auto Player : Game::GetPlayers())
		{
			auto HealthComp = UPlayerHealthComponent::GetOrCreate(Player);
			HealthComp.OnStartDying.AddUFunction(this, n"HandlePlayerDeath");
		}
	}

	UFUNCTION()
	private void HandlePlayerDeath()
	{
		if (!bHardModeEnabled)
			return;

		SharedHP--;
		HardModeWidget.SetHP(SharedHP);

		if (SharedHP <= 0)
			TriggerGameOver();	
	}

	UFUNCTION()
	void ActivateHardMode()
	{
		HardModeWidget = Widget::AddFullscreenWidget(HardModeWidgetClass);
		bHardModeEnabled = true;

		for (auto Player : Game::Players)
		{
			Player.ApplySettings(DefaultHPSettings, this, EHazeSettingsPriority::Final);
		}
	}

	private void TriggerGameOver()
	{
		OnTriggeredGameOver.Broadcast();

		for (auto Player : Game::Players)
		{
			Player.ApplySettings(GameOverHPSettings, this, EHazeSettingsPriority::EHazeSettingsPriority_MAX);
			Player.KillPlayer();
		}
	}
};

UCLASS(Abstract)
class USkylineBallBossHardModeWidget : UHazeUserWidget
{
	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void SetHP(int NewHP) {}
}