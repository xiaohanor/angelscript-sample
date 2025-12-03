UCLASS(Abstract)
class UIslandRedBlueStickyGrenadeUserComponent : UActorComponent
{
	access GrenadeActiveCapability = private, UIslandRedBlueStickyGrenadeActiveCapability;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AIslandRedBlueStickyGrenade> GrenadeClass;

	UPROPERTY(EditDefaultsOnly, Category = "Force Feedback & Camera Shake")
	UForceFeedbackEffect DetonateForceFeedback;

	UPROPERTY(EditDefaultsOnly, Category = "Force Feedback & Camera Shake")
	UForceFeedbackEffect DetonateWorldForceFeedback;

	UPROPERTY(EditDefaultsOnly, Category = "Force Feedback & Camera Shake")
	TSubclassOf<UCameraShakeBase> DetonateCamShake;

	UPROPERTY(EditDefaultsOnly, Category = "Force Feedback & Camera Shake")
	TSubclassOf<UCameraShakeBase> FullscreenDetonateCamShake;

	UPROPERTY(EditDefaultsOnly, Category = "Force Feedback & Camera Shake")
	UForceFeedbackEffect AttachForceFeedback;

	/** This force feedback will play when the grenade fails (when you either throw it on a force field of the wrong color or if it despawns because it falls out of range) */
	UPROPERTY(EditDefaultsOnly, Category = "Force Feedback & Camera Shake")
	UForceFeedbackEffect FailForceFeedback;

	UPROPERTY(EditDefaultsOnly)
	UHazeCapabilitySheet GrenadeSheet;

	AHazePlayerCharacter PlayerOwner;
	AIslandRedBlueStickyGrenade Grenade;
	UIslandRedBlueStickyGrenadeSettings Settings;
	UIslandRedBlueWeaponUserComponent WeaponUserComp;

	float LastGrenadeThrow = -100.0;
	bool bCurrentGrenadeThrowingHandIsRight = false;
	bool bLastGrenadeThrowingHandWasRight = false;
	int ExplosionIndex = 0;
	access:GrenadeActiveCapability bool bInternal_GrenadeSheetIsActive = false;
	private TArray<FInstigator> GrenadeIndicatorLitInstigators;
	private TArray<FInstigator> GrenadeThrowBlockers;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		Settings = UIslandRedBlueStickyGrenadeSettings::GetSettings(PlayerOwner);
		
		Grenade = SpawnActor(GrenadeClass, bDeferredSpawn = true);
		Grenade.PlayerOwner = PlayerOwner;
		Grenade.MakeNetworked(this, n"_SpawnedGrenade");
		FinishSpawningActor(Grenade);

		WeaponUserComp = UIslandRedBlueWeaponUserComponent::Get(PlayerOwner);

		FHazeDevInputInfo SwitchInputInfo;
		SwitchInputInfo.Name = n"Toggle Sticky Grenades";
		SwitchInputInfo.Category = n"Island";
		SwitchInputInfo.OnTriggered.BindUFunction(this, n"HandleDevEnableStickyGrenade");
		SwitchInputInfo.OnStatus.BindUFunction(this, n"OnStickyGrenadeStatus");
		SwitchInputInfo.AddKey(EKeys::Gamepad_FaceButton_Bottom);
		SwitchInputInfo.AddKey(EKeys::H);

		PlayerOwner.RegisterDevInput(SwitchInputInfo);

		// Offset one of the players' explosion index so they don't overlap
		// Can have an effect if both players are hitting the same forcefield (that is changing color)
		if (PlayerOwner.IsZoe())
			ExplosionIndex = 0x40000000;
	}

	void BlockGrenadeThrowing(FInstigator Instigator)
	{
		GrenadeThrowBlockers.AddUnique(Instigator);
	}

	void UnblockGrenadeThrowing(FInstigator Instigator)
	{
		GrenadeThrowBlockers.RemoveSingleSwap(Instigator);
	}

	bool IsGrenadeThrowingBlocked() const
	{
		return GrenadeThrowBlockers.Num() > 0;
	}

	bool IsGrenadeThrown() const
	{
		return Grenade.IsGrenadeThrown();
	}

	bool IsGrenadeAttached() const
	{
		return Grenade.IsGrenadeAttached();
	}

	UFUNCTION(BlueprintPure)
	bool IsGrenadeSheetActive()
	{
		return bInternal_GrenadeSheetIsActive;
	}

	void DetermineGrenadeThrowingHand()
	{
		if(WeaponUserComp.IsLeftHandBlocked() != WeaponUserComp.IsRightHandBlocked())
		{
			bCurrentGrenadeThrowingHandIsRight = !WeaponUserComp.IsRightHandBlocked();
		}
		else
		{
			bCurrentGrenadeThrowingHandIsRight = !bLastGrenadeThrowingHandWasRight;
		}

		bLastGrenadeThrowingHandWasRight = bCurrentGrenadeThrowingHandIsRight;
	}

	void AddGrenadeIndicatorLitInstigator(FInstigator Instigator)
	{
		GrenadeIndicatorLitInstigators.AddUnique(Instigator);
	}

	void RemoveGrenadeIndicatorLitInstigator(FInstigator Instigator)
	{
		GrenadeIndicatorLitInstigators.RemoveSingleSwap(Instigator);
	}

	bool IsGrenadeIndicatorLit()
	{
		return GrenadeIndicatorLitInstigators.Num() > 0;
	}

	UFUNCTION()
	private void HandleDevEnableStickyGrenade()
	{
		if(bInternal_GrenadeSheetIsActive)
		{
			Game::Mio.StopCapabilitySheet(UIslandRedBlueStickyGrenadeUserComponent::Get(Game::Mio).GrenadeSheet, World.GetLevelScriptActor());
			Game::Zoe.StopCapabilitySheet(UIslandRedBlueStickyGrenadeUserComponent::Get(Game::Zoe).GrenadeSheet, World.GetLevelScriptActor());
			Print("Disabled Sticky Grenades for Both Players");
		}
		else
		{
			Game::Mio.StartCapabilitySheet(UIslandRedBlueStickyGrenadeUserComponent::Get(Game::Mio).GrenadeSheet, World.GetLevelScriptActor());
			Game::Zoe.StartCapabilitySheet(UIslandRedBlueStickyGrenadeUserComponent::Get(Game::Zoe).GrenadeSheet, World.GetLevelScriptActor());
			Print("Enabled Sticky Grenades for Both Players");
		}
	}

	UFUNCTION()
	private void OnStickyGrenadeStatus(FString& OutDescription, FLinearColor& OutColor)
	{
		if(bInternal_GrenadeSheetIsActive)
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
}