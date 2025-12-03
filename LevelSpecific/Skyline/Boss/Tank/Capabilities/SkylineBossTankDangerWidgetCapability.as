class USkylineBossTankDangerWidgetCapability : USkylineBossTankChildCapability
{
	TPerPlayer<UHazeUserWidget> DangerWidget;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Owner.bIsControlledByCutscene)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Owner.bIsControlledByCutscene)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for (auto Player : Game::Players)
		{
			DangerWidget[Player] = Player.AddWidget(BossTank.DangerWidgetClass);
			DangerWidget[Player].AttachWidgetToComponent(BossTank.WeaponTargetableComp);
	//		DangerWidget[Player].SetWidgetRelativeAttachOffset(FVector::UpVector * 500.0);
		}			
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for (auto Player : Game::Players)
			Player.RemoveWidget(DangerWidget[Player]);
	}
};