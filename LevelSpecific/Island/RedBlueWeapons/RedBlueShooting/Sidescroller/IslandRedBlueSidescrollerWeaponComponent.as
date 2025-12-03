class UIslandRedBlueSidescrollerWeaponUserComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UNiagaraSystem SidescrollerAimLaserEffect;

	UIslandRedBlueWeaponUserComponent WeaponUserComp;
	bool bUseNew8DirectionAiming = false;
	AHazePlayerCharacter PlayerOwner;
	AIslandRedBlueSidescrollerSpotlightActor SpotlightActor;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		WeaponUserComp = UIslandRedBlueWeaponUserComponent::Get(PlayerOwner);

		FHazeDevInputInfo DirectionDevInput;
		DirectionDevInput.Category = n"Island";
		DirectionDevInput.Name = n"Toggle Use New 8 Direction Aiming";
		DirectionDevInput.OnTriggered.BindUFunction(this, n"ToggleDevNew8DirectionAiming");
		DirectionDevInput.OnStatus.BindUFunction(this, n"On8DirectionAimingStatus");
		DirectionDevInput.AddKey(EKeys::G);
		DirectionDevInput.AddKey(EKeys::Gamepad_FaceButton_Right);
		PlayerOwner.RegisterDevInput(DirectionDevInput);

		FHazeDevInputInfo ClampConeDevInput;
		ClampConeDevInput.Category = n"Island";
		ClampConeDevInput.Name = n"Toggle Use New Clamp Cone Width";
		ClampConeDevInput.OnTriggered.BindUFunction(this, n"ToggleClampConeWidth");
		ClampConeDevInput.OnStatus.BindUFunction(this, n"OnClampConeWidthStatus");
		ClampConeDevInput.AddKey(EKeys::B);
		ClampConeDevInput.AddKey(EKeys::Gamepad_FaceButton_Left);
		PlayerOwner.RegisterDevInput(ClampConeDevInput);
	}

	UFUNCTION()
	private void OnClampConeWidthStatus(FString& OutDescription, FLinearColor& OutColor)
	{
		auto SidescrollerAssaultSettings = UIslandRedBlueSidescrollerAssaultSettings::GetSettings(PlayerOwner);
		if(SidescrollerAssaultSettings.bClampMaxConeWidth)
		{
			OutDescription = "[ON]";
			OutColor = FLinearColor::Green;
		}
		else
		{
			OutDescription = "[OFF]";
			OutColor = FLinearColor::Red;
		}
	}

	UFUNCTION()
	private void On8DirectionAimingStatus(FString& OutDescription, FLinearColor& OutColor)
	{
		if(bUseNew8DirectionAiming)
		{
			OutDescription = "[ON]";
			OutColor = FLinearColor::Green;
		}
		else
		{
			OutDescription = "[OFF]";
			OutColor = FLinearColor::Red;
		}
	}

	UFUNCTION()
	private void ToggleDevNew8DirectionAiming()
	{
		auto OtherWeaponComp = UIslandRedBlueSidescrollerWeaponUserComponent::Get(PlayerOwner.OtherPlayer);
		bUseNew8DirectionAiming = !bUseNew8DirectionAiming;
		OtherWeaponComp.bUseNew8DirectionAiming = bUseNew8DirectionAiming;

		if(bUseNew8DirectionAiming)
			Print("Turned on 8 direction aiming for Both players!");
		else
			Print("Turned off 8 direction aiming for Both players!");
	}

	UFUNCTION()
	private void ToggleClampConeWidth()
	{
		ToggleClampConeWidthForPlayer(Game::Mio);
		ToggleClampConeWidthForPlayer(Game::Zoe);

		auto SidescrollerAssaultSettings = UIslandRedBlueSidescrollerAssaultSettings::GetSettings(PlayerOwner);
		if(SidescrollerAssaultSettings.bClampMaxConeWidth)
			Print("Turned on clamp cone width for Both players!");
		else
			Print("Turned off clamp cone width for Both players!");
	}

	private void ToggleClampConeWidthForPlayer(AHazePlayerCharacter Player)
	{
		auto SidescrollerAssaultSettings = UIslandRedBlueSidescrollerAssaultSettings::GetSettings(Player);
		bool bPreviousClampConeWidth = SidescrollerAssaultSettings.bClampMaxConeWidth;
		Player.ClearSettingsByInstigator(this);
		if(bPreviousClampConeWidth != SidescrollerAssaultSettings.bClampMaxConeWidth)
			return;

		UIslandRedBlueSidescrollerAssaultSettings::SetClampMaxConeWidth(Player, !SidescrollerAssaultSettings.bClampMaxConeWidth, this, EHazeSettingsPriority::Final);
	}
}