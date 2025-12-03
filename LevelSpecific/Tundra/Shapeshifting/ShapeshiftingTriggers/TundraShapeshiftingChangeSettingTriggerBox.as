
event void FTundraPlayerShapeTriggerEvent(AHazePlayerCharacter Player, ETundraShapeshiftShape CurrentShape);

/**
 * Trigger volume that changes settings on each shape when enters into it
 */
UCLASS(HideCategories = "Collision BrushSettings Rendering Input Actor LOD Cooking Debug WorldPartition HLOD DataLayers", ComponentWrapperClass)
class ATundraShapeshiftingChangeSettingTriggerBox : AVolume
{
    default Shape::SetVolumeBrushColor(this, FLinearColor(1.0, 0.0, 0.8, 1.0));
	default BrushComponent.SetCollisionProfileName(n"TriggerOnlyPlayer");

	// Whether the trigger should ignore networking and only trigger locally
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Player Trigger", AdvancedDisplay)
	bool bTriggerLocally = false;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Player Trigger")
	UTundraShapeshiftingChangeSettingTriggerBoxSettings TriggerBoxSettings;

    UPROPERTY(Category = "Player Trigger")
    FTundraPlayerShapeTriggerEvent OnShapeEnter;

    UPROPERTY(Category = "Player Trigger")
    FTundraPlayerShapeTriggerEvent OnShapeLeave;

    private TPerPlayer<FPlayerShapeTriggerChangeSettingsPerPlayerData> PerPlayerData;
	private TArray<FInstigator> DisableInstigators;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(TriggerBoxSettings != nullptr)
			return;

		Print("Please assign trigger box settings in ChangeSettingTriggerBox", 5.0, FLinearColor::Red);
		DisablePlayerTrigger(this);
	}

    UFUNCTION(Category = "Player Trigger")
    void EnablePlayerTrigger(FInstigator Instigator)
    {
		DisableInstigators.Remove(Instigator);
        UpdateAlreadyInsidePlayers();
    }

    UFUNCTION(Category = "Player Trigger")
    void DisablePlayerTrigger(FInstigator Instigator)
    {
		DisableInstigators.AddUnique(Instigator);
        UpdateAlreadyInsidePlayers();
    }

	UFUNCTION(Category = "Player Trigger")
	bool IsEnabled() const
	{
		if (DisableInstigators.Num() != 0)
			return false;
		return true;
	}

	// Manually update which players are inside, we may have missed overlap events due to disable or streaming
	private void UpdateAlreadyInsidePlayers()
	{
		for (auto Player : Game::Players)
		{
			if (!Player.HasControl() && !bTriggerLocally)
				continue;

			auto& PlayerData = PerPlayerData[Player];
			bool bIsInside = false;
			if (IsEnabled())
			{
				if (Player.CapsuleComponent.TraceOverlappingComponent(BrushComponent))
					bIsInside = true;
			}

			auto Shapeshift = UTundraPlayerShapeshiftingComponent::Get(Player);

			if(Shapeshift == nullptr)
				return;

			if(PlayerData.bIsPlayerInside && bIsInside && PlayerData.CurrentShape != Shapeshift.CurrentShapeType)
			{
				Internal_OnShapeLeave(PlayerData, Player, PlayerData.CurrentShape);
				Internal_OnShapeEnter(PlayerData, Player, Shapeshift.CurrentShapeType);
			}
			else if (PlayerData.bIsPlayerInside && !bIsInside)
			{
				Internal_OnShapeLeave(PlayerData, Player, Shapeshift.CurrentShapeType);
			}
			else if (!PlayerData.bIsPlayerInside && bIsInside)
			{
				Internal_OnShapeEnter(PlayerData, Player, Shapeshift.CurrentShapeType);
			}
		}
	}

	UFUNCTION()
	private void OnChangeShape(AHazePlayerCharacter Player, ETundraShapeshiftShape NewShape)
	{
		UpdateAlreadyInsidePlayers();
	}

    UFUNCTION(BlueprintOverride)
    private void ActorBeginOverlap(AActor OtherActor)
    {
		if (!IsEnabled())
            return;

        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
        if (Player == nullptr)
            return;
		if (!Player.HasControl() && !bTriggerLocally)
			return;

		UTundraPlayerShapeshiftingComponent::Get(Player).OnChangeShape.AddUFunction(this, n"OnChangeShape");

		auto& PlayerData = PerPlayerData[Player];
		auto Shapeshift = UTundraPlayerShapeshiftingComponent::Get(Player);

		if(Shapeshift == nullptr)
			return;

		if (!PlayerData.bIsPlayerInside)
		{
			Internal_OnShapeEnter(PlayerData, Player, Shapeshift.CurrentShapeType);
		}
	}

    UFUNCTION(BlueprintOverride)
    private void ActorEndOverlap(AActor OtherActor)
    {
		if (!IsEnabled())
            return;

        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
        if (Player == nullptr)
            return;
		if (!Player.HasControl() && !bTriggerLocally)
			return;

		UTundraPlayerShapeshiftingComponent::Get(Player).OnChangeShape.UnbindObject(this);

		auto& PlayerData = PerPlayerData[Player];
		auto Shapeshift = UTundraPlayerShapeshiftingComponent::Get(Player);

		if(Shapeshift == nullptr)
			return;

		if (PlayerData.bIsPlayerInside)
		{
			Internal_OnShapeLeave(PlayerData, Player, Shapeshift.CurrentShapeType);
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbShapeEnter(AHazePlayerCharacter Player, ETundraShapeshiftShape CurrentShape)
	{
		OnShapeEnter.Broadcast(Player, CurrentShape);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbShapeLeave(AHazePlayerCharacter Player, ETundraShapeshiftShape CurrentShape)
	{
		OnShapeLeave.Broadcast(Player, CurrentShape);
	}

	private void Internal_OnShapeLeave(FPlayerShapeTriggerChangeSettingsPerPlayerData& PlayerData, AHazePlayerCharacter Player, ETundraShapeshiftShape CurrentShape)
	{
		PlayerData.bIsPlayerInside = false;
		PlayerData.CurrentShape = ETundraShapeshiftShape::None;

		ResetSettings(Player, CurrentShape);

		if (!bTriggerLocally)
			CrumbShapeLeave(Player, CurrentShape);
		else
			OnShapeLeave.Broadcast(Player, CurrentShape);
	}

	private void Internal_OnShapeEnter(FPlayerShapeTriggerChangeSettingsPerPlayerData& PlayerData, AHazePlayerCharacter Player, ETundraShapeshiftShape CurrentShape)
	{
		PlayerData.bIsPlayerInside = true;
		PlayerData.CurrentShape = CurrentShape;

		ApplySettings(Player, CurrentShape);

		if (!bTriggerLocally)
			CrumbShapeEnter(Player, CurrentShape);
		else
			OnShapeEnter.Broadcast(Player, CurrentShape);
	}

	private void ApplySettings(AHazePlayerCharacter Player, ETundraShapeshiftShape CurrentShape) 
	{
		switch(CurrentShape)
		{
			case ETundraShapeshiftShape::Small:
				if(Player.IsZoe()) TriggerBoxSettings.FairySettingsOverride.Apply(Player, this); // Fairy
				else TriggerBoxSettings.OtterSettingsOverride.Apply(Player, this); // Otter
				break;

			case ETundraShapeshiftShape::Player:
				if(Player.IsZoe()) TriggerBoxSettings.ZoeSettingsOverride.Apply(Player, this); // Zoe player
				else TriggerBoxSettings.MioSettingsOverride.Apply(Player, this); // Mio player
				break;

			case ETundraShapeshiftShape::Big:
				if(Player.IsZoe()) TriggerBoxSettings.TreeGuardianSettingsOverride.Apply(Player, this); // Tree guardian
				else TriggerBoxSettings.SnowMonkeySettingsOverride.Apply(Player, this); // Snow monkey
				break;

			default: break;
		}
	}

	private void ResetSettings(AHazePlayerCharacter Player, ETundraShapeshiftShape CurrentShape) 
	{
		switch(CurrentShape)
		{
			case ETundraShapeshiftShape::Small:
				if(Player.IsZoe()) TriggerBoxSettings.FairySettingsOverride.Reset(Player, this); // Fairy
				else TriggerBoxSettings.OtterSettingsOverride.Reset(Player, this); // Otter
				break;

			case ETundraShapeshiftShape::Player:
				if(Player.IsZoe()) TriggerBoxSettings.ZoeSettingsOverride.Reset(Player, this); // Zoe player
				else TriggerBoxSettings.MioSettingsOverride.Reset(Player, this); // Mio player
				break;

			case ETundraShapeshiftShape::Big:
				if(Player.IsZoe()) TriggerBoxSettings.TreeGuardianSettingsOverride.Reset(Player, this); // Tree guardian
				else TriggerBoxSettings.SnowMonkeySettingsOverride.Reset(Player, this); // Snow monkey
				break;

			default: break;
		}
	}
}

struct FPlayerShapeTriggerChangeSettingsPerPlayerData
{
	bool bIsPlayerInside = false;
	ETundraShapeshiftShape CurrentShape = ETundraShapeshiftShape::None;
};