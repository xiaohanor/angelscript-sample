class USolarFlareTriggerShieldComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<ASolarFlareTriggerShield> TriggerShieldClass;
	ASolarFlareTriggerShield Shield;

	UPROPERTY()
	TSubclassOf<USolarFlareTriggerShieldEnergyWidget> WidgetClass;
	USolarFlareTriggerShieldEnergyWidget Widget;

	UPROPERTY()
	UForceFeedbackEffect ShieldTriggeredRumble;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> ShieldTriggeredShake;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	UPROPERTY()
	FVector WidgetAttachOffset = FVector(0,0, 100);

	UPROPERTY()
	FLinearColor NormalColor;

	UPROPERTY()
	FLinearColor DepletedColor;

	UPROPERTY()
	UAnimSequence AnimBlock;

	ASolarFlareTriggerShieldAttachContraption Contraption; 

	private float ShieldEnergy;
	bool bHasTriggerShield;
	bool bEnergyWasDepleted;
	int TotalActivations;
	int MaxTotalActivations = 2;

	ASolarFlareTriggerShield SpawnShield(AHazePlayerCharacter Player)
	{
		Shield = SpawnActor(TriggerShieldClass, Player.ActorLocation);
		return Shield;
	}

	void SetShieldAvailable(AHazePlayerCharacter Player)
	{
		ASolarFlareSun Sun = TListedActors<ASolarFlareSun>().Single;
		if (Sun.Phase == ESolarFlareSunPhase::BlackHole || Sun.Phase == ESolarFlareSunPhase::Implode)
			return;

		bHasTriggerShield = true;
		Widget = Player.AddWidget(WidgetClass);
		Widget.AttachWidgetToComponent(Player.AttachmentRoot);
		Widget.SetWidgetRelativeAttachOffset(WidgetAttachOffset);
		Widget.ApplyColor(NormalColor);
		SetShieldEnergy(1.0);

		FSolarFlareTriggerShieldEffectHandlerParams Params;
		Params.Player = Player;
		Params.ShieldLocation = Shield.ActorLocation;

		Shield.BP_OnShieldCollected(Player);
		USolarFlareTriggerShieldEffectHandler::Trigger_OnCollect(Shield, Params);
		AddPrompt(Player);
	}

	void SetShieldUnavailable(AHazePlayerCharacter Player)
	{
		bHasTriggerShield = false;
		Shield.OnShieldUnavailable(Player);
		RemovePrompt(Player);
		Player.RemoveWidget(Widget);
	}

	void AlterShieldEnergy(float Amount)
	{
		ShieldEnergy += Amount;
		ShieldEnergy = Math::Clamp(ShieldEnergy, 0, 1);

		if (Widget != nullptr)
		{
			Widget.SetWidgetShieldEnergy(ShieldEnergy);
		}
	}

	void SetShieldEnergy(float NewAmount)
	{
		ShieldEnergy = NewAmount;

		if (Widget != nullptr)
			Widget.SetWidgetShieldEnergy(ShieldEnergy);
	}

	float GetShieldEnergy() const
	{
		return ShieldEnergy;
	}

	void SetDepleted()
	{
		bEnergyWasDepleted = true;

		if (Widget == nullptr)
			return;
		
		Widget.ApplyColor(DepletedColor);
	}

	void SetNotDepleted()
	{
		bEnergyWasDepleted = false;

		if (Widget == nullptr)
			return;

		Widget.ApplyColor(NormalColor);
	}

	void AddPrompt(AHazePlayerCharacter Player)
	{
		if (TotalActivations > MaxTotalActivations)
			return;

		FTutorialPrompt InputPrompt;
		InputPrompt.Action = ActionNames::PrimaryLevelAbility;
		InputPrompt.DisplayType = ETutorialPromptDisplay::ActionHold;
		InputPrompt.Text = NSLOCTEXT("SolarFlare", "TriggerShield", "Activate Shield");
		Player.ShowTutorialPrompt(InputPrompt, this);
	}

	void RemovePrompt(AHazePlayerCharacter Player)
	{
		Player.RemoveTutorialPromptByInstigator(this);
	}

	void PlayTriggerFeedback(AHazePlayerCharacter Player)
	{	
		Player.PlayCameraShake(ShieldTriggeredShake, this);
		Player.PlayForceFeedback(ShieldTriggeredRumble, false, true, this);
	}
};