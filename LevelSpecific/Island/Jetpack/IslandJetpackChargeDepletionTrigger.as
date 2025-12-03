class AIslandJetpackChargeDepletionTrigger : APlayerTrigger
{
	default Shape::SetVolumeBrushColor(this, FLinearColor::Yellow);
	default BrushComponent.LineThickness = 10;

	// How much charge is lost per second while jetpacking
	UPROPERTY(EditAnywhere)
	float ChargeDepletionSpeed = UIslandJetpackSettings.DefaultObject.ChargeDepletionSpeed;

	/** How much charge is lost per second while boosting */
	UPROPERTY(EditAnywhere)
	float BoostChargeDepletionSpeed = UIslandJetpackSettings.DefaultObject.BoostChargeDepletionSpeed;

	/** How much charge is lost instantly when activating the jetpack */
	UPROPERTY(EditAnywhere)
	float BoostActivationDepletion = UIslandJetpackSettings.DefaultObject.BoostActivationDepletion;

	UPROPERTY(EditAnywhere)
	float DashActivationDepletion = UIslandJetpackSettings.DefaultObject.DashActivationDepletion;

	UIslandJetpackSettings Settings;
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
		UIslandJetpackSettings::SetChargeDepletionSpeed(Player, ChargeDepletionSpeed, this);
		UIslandJetpackSettings::SetBoostChargeDepletionSpeed(Player, BoostChargeDepletionSpeed, this);
		UIslandJetpackSettings::SetBoostActivationDepletion(Player, BoostActivationDepletion, this);
		UIslandJetpackSettings::SetDashActivationDepletion(Player, DashActivationDepletion, this);
	}

	UFUNCTION()
	private void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		UIslandJetpackSettings::ClearChargeDepletionSpeed(Player, this);
		UIslandJetpackSettings::ClearBoostChargeDepletionSpeed(Player, this);
		UIslandJetpackSettings::ClearBoostActivationDepletion(Player, this);
		UIslandJetpackSettings::ClearDashActivationDepletion(Player, this);
	}
};