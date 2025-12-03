class AIslandRedBlueUpgradeStation : ADoubleInteractionActor
{
	UPROPERTY(EditAnywhere)
	EIslandRedBlueWeaponUpgradeType WeaponToUpgradeTo;

	/* These sheets will be activated on Mio when interacting with this upgrade station (these have to also be added to the level BP under initially stopped sheets) */
	UPROPERTY(EditAnywhere)
	TArray<UHazeCapabilitySheet> MioSheetsToStart;

	/* These sheets will be activated on Zoe when interacting with this upgrade station (these have to also be added to the level BP under initially stopped sheets) */
	UPROPERTY(EditAnywhere)
	TArray<UHazeCapabilitySheet> ZoeSheetsToStart;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		OnDoubleInteractionCompleted.AddUFunction(this, n"OnDoubleInteractionCompleted");
		OnCompletedBlendingOut.AddUFunction(this, n"OnCompletedBlendingOut");
	}

	UFUNCTION()
	private void OnDoubleInteractionCompleted()
	{
		for(auto Player : Game::GetPlayers())
		{
			auto UserComp = UIslandRedBlueWeaponUserComponent::Get(Player);
			UserComp.CurrentUpgradeType = WeaponToUpgradeTo;
			UserComp.AttachWeaponToHand(this);

			TArray<UHazeCapabilitySheet>& RelevantSheetArray = Player.IsMio() ? MioSheetsToStart : ZoeSheetsToStart;
			for(int i = 0; i < RelevantSheetArray.Num(); i++)
			{
				Player.StartCapabilitySheet(RelevantSheetArray[i], this);
			}
		}
	}

	UFUNCTION()
	private void OnCompletedBlendingOut(AHazePlayerCharacter Player, ADoubleInteractionActor Interaction, UInteractionComponent InteractionComponent)
	{
		auto UserComp = UIslandRedBlueWeaponUserComponent::Get(Player);
		UserComp.AttachWeaponToThigh(this);
	}
}