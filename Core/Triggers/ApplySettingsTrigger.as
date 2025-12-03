struct FApplySettingsTriggerEntry
{
	UPROPERTY()
	UHazeComposableSettings Asset;

	UPROPERTY()
    EHazeSettingsPriority Priority = EHazeSettingsPriority::Gameplay;

	UPROPERTY()
	EHazeSelectPlayer ApplyToPlayers = EHazeSelectPlayer::Both;
};

/**
 * Generic actor for applying and clearing settings when a player enters and leaves the trigger volume.
 */
class AApplySettingsTrigger : APlayerTrigger
{
    default Shape::SetVolumeBrushColor(this, FLinearColor(0.0, 0.6, 0.9, 1.0));

    /**
     * These settings will be applied to the player in OnPlayerEnter.
     */
	UPROPERTY(EditInstanceOnly, Category = "Apply Setting Trigger")
	TArray<FApplySettingsTriggerEntry> SettingsToApply;

#if EDITOR
    UPROPERTY(DefaultComponent)
    UEditorBillboardComponent EditorBillboard;
    default EditorBillboard.SpriteName = "S_TriggerBox";
	default EditorBillboard.RelativeScale3D = FVector(0.5);
#endif

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        Super::BeginPlay();

        OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
        OnPlayerLeave.AddUFunction(this, n"OnPlayerLeave");
    }

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		Super::EndPlay(EndPlayReason);
		
		for(auto Player : Game::Players)
		{
			if(Player == nullptr)
				continue;

			ClearSettingsOnActor(Player);
		}
	}

    UFUNCTION()
    protected void OnPlayerEnter(AHazePlayerCharacter Player)
    {
		ApplySettingsOnActor(Player, Player);
    }

    UFUNCTION()
    protected void OnPlayerLeave(AHazePlayerCharacter Player)
    {
		ClearSettingsOnActor(Player);
    }

	protected void ApplySettingsOnActor(AHazeActor Actor, AHazePlayerCharacter ApplyForPlayer)
	{
		for(auto Settings : SettingsToApply)
		{
			if(Settings.Asset == nullptr)
				continue;
			if(!ApplyForPlayer.IsSelectedBy(Settings.ApplyToPlayers))
				continue;

			Actor.ApplySettings(Settings.Asset, this, Settings.Priority);
		}
	}

	protected void ClearSettingsOnActor(AHazeActor Actor)
	{
		Actor.ClearSettingsByInstigator(this);
	}
}