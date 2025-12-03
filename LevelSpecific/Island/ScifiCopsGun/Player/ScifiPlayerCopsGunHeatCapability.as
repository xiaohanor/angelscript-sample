class UScifiPlayerCopsGunHeatCapability : UHazeCapability
{
	default CapabilityTags.Add(n"CopsGun");
	default CapabilityTags.Add(n"CopsGunHeat");

	default TickGroup = EHazeTickGroup::BeforeGameplay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	AScifiCopsGun LeftWeapon;
	AScifiCopsGun RightWeapon;
	UScifiPlayerCopsGunManagerComponent Manager;
	UPlayerAimingComponent AimingComp;
	UScifiPlayerCopsGunSettings Settings;
	
	UScifiCopsGunHeatWidget HeatWidget;
	float TriggeredOverheatTime = 0;
	//float PreviousRelativeHeightOffset = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		Manager = UScifiPlayerCopsGunManagerComponent::Get(Player);
		AimingComp = UPlayerAimingComponent::Get(Player);
		Settings = Manager.Settings;

		HeatWidget = Player.AddWidget(Manager.HeatWidgetClass);
		Player.RemoveWidget(HeatWidget);

		Manager.EnsureWeaponSpawn(Player, LeftWeapon, RightWeapon);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Manager.CurrentHeat < KINDA_SMALL_NUMBER)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// if(!Weapon.IsWeaponAttachedToHand())
		// 	return true;

		// if(Weapon.IsRecalling())
		// 	return true;

		if(Manager.HasTriggeredOverheat())
			return false;

		if(Manager.CurrentHeat >= KINDA_SMALL_NUMBER)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.AddExistingWidget(HeatWidget);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Manager.ClearHeat();
		Player.RemoveWidget(HeatWidget);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!Manager.HasTriggeredOverheat() && Manager.CurrentHeat >= Settings.MaxHeat - KINDA_SMALL_NUMBER)
		{
			Manager.TriggerOverheat();
			TriggeredOverheatTime = Time::GetGameTimeSeconds();

			if(HeatWidget != nullptr)
			{
				HeatWidget.HeatAlpha = 1;
				HeatWidget.OverHeatAlpha = 1;
			}

			FScifiPlayerCopsGunOverheatData OverheatEffectData;
			OverheatEffectData.TimeUntilWeStartTheCooldown = Settings.OverheatCooldownDelayTime;
			OverheatEffectData.CooldownTime = Settings.OverheatCooldownTime;
			UScifiCopsGunEventHandler::Trigger_OnOverheat(LeftWeapon, OverheatEffectData);
			UScifiCopsGunEventHandler::Trigger_OnOverheat(RightWeapon, OverheatEffectData);
		}

		if(!Manager.HasTriggeredOverheat())
		{
			CooldownWeapon(LeftWeapon, DeltaTime);
			CooldownWeapon(RightWeapon, DeltaTime);

			float HeatAlpha = 0;
			if(Settings.MaxHeat > 0)
			 	HeatAlpha = Manager.CurrentHeat / Settings.MaxHeat;
			
			if(HeatWidget != nullptr)
			{
				HeatWidget.HeatAlpha = HeatAlpha;
				HeatWidget.OverHeatAlpha = 0;	
			}	
		}
		else 
		{
			float OverHeatAlpha = 1.0;

			if(Time::GetGameTimeSeconds() >= TriggeredOverheatTime + Settings.OverheatCooldownDelayTime)
			{
				if(Settings.OverheatCooldownTime > KINDA_SMALL_NUMBER)
				{
					OverHeatAlpha = Time::GetGameTimeSince(TriggeredOverheatTime + Settings.OverheatCooldownDelayTime) / Settings.OverheatCooldownTime;
					OverHeatAlpha = 1.0 - Math::Clamp(OverHeatAlpha, 0.0, 1.0);
				}
				else
				{
					OverHeatAlpha = 0.0;
				}
			}

			if(HeatWidget != nullptr)
				HeatWidget.OverHeatAlpha = OverHeatAlpha;

			// Clear the heat
			if(OverHeatAlpha < KINDA_SMALL_NUMBER)
			{
				Manager.ClearHeat();
				HeatWidget.HeatAlpha = 0;			
			}
		}

		// Always update the widget
		if(HeatWidget != nullptr)
		{
			HeatWidget.CurentHeat = Manager.CurrentHeat;

			//FVector2D ScreenPosition = AimingComp.GetCrosshairScreenSpacePosition();
			//ScreenPosition.Y += ActiveDuration;
			//HeatWidget.SetPositionInViewport(FVector2D(0, 20500), false);
			//HeatWidget.AlignmentInViewport = ScreenPosition;
			// FAnchors Anchor;
			// Anchor.Minimum = ScreenPosition;
			// Anchor.Maximum = ScreenPosition;
	
			//WidgetTransform.Translation = 
			//HeatWidget.AnchorsInViewport = Anchor;
	

			//HeatWidget.
	

			// Test.Anchors = CrosshairAnchors;
			// Test.Offsets = FMargin();
			// Test.Alignment = FVector2D(0.5, 0.5);
			// Test.Position = FVector2D(0.0, 0.0);
			
			//HeatWidget.WidgetRelativeAttachOffset = FVector(ScreenPos.X, ScreenPos.Y, 0);
		}
		
		// if (HeatWidget.CurentHeat >= KINDA_SMALL_NUMBER)
		// {
		// 	// if(!HeatWidget.bIsAdded)
		// 	// {
		// 	// 	Player.AddExistingWidget(HeatWidget);
		// 	// 	//HeatWidget.AttachWidgetToComponent(Player.Mesh, Manager.HandAttachStocket[Weapon.AttachType]);
		// 	// }

		// 	// auto CrosshairWidget = Cast<UScifiCopsGunCrosshair>(AimingComp.GetCrosshairWidget(Manager));
		// 	// if(CrosshairWidget != nullptr)
		// 	// {
		// 	// 	CrosshairWidget.
		// 	// 	//HeatWidget.SetWidgetWorldPosition(AttachLocation);
		// 	// }

		// 	// const FVector AttachLocation = GetWidgetOffset(DeltaTime);
		// 	// HeatWidget.SetWidgetWorldPosition(AttachLocation);
		// }
		// if(Weapon.CurrentHeat < KINDA_SMALL_NUMBER)
		// {
		// 	// if(HeatWidget.bIsAdded)
		// 	// 	Player.RemoveWidget(HeatWidget);

		// 	if(!Weapon.bPlayerWantsToShoot)
		// 		PreviousRelativeHeightOffset = 0;
		// }
		
			
	}

	void CooldownWeapon(AScifiCopsGun Weapon, float DeltaTime)
	{
		float TimeSinceShot = Time::GetGameTimeSince(Weapon.LastShotGameTime);
		if(Manager.CurrentHeat > 0 && !Weapon.bIsShooting && TimeSinceShot > Settings.HeatCooldownDelayTime + Settings.CooldownBetweenBullets)
		{
			Manager.SetHeat(Math::FInterpConstantTo(Manager.CurrentHeat, 0.0, DeltaTime, Settings.HeatCooldownSpeedWhenNotShooting));
		}	
	}

	// FVector GetWidgetOffset(float DeltaTime)
	// {
	// 	FVector RightVector = Player.ControlRotation.RightVector;
	// 	//FVector AttachLocation = Player.Mesh.GetSocketLocation(Manager.HandAttachStocket[Weapon.AttachType]);
	// 	FVector AttachLocation = Player.Mesh.GetSocketLocation(n"LeftShoulder");
		
	// 	FVector Offset = FVector::ZeroVector;
	// 	if(Weapon.IsLeftWeapon())
	// 		Offset = -RightVector * 30;
	// 	else
	// 		Offset = RightVector * 30;

	// 	AttachLocation += Offset;
	// 	float NewHeightOffset = (AttachLocation - Player.ActorLocation).DotProduct(Player.MovementWorldUp);

	// 	float LerpSpeed = 2;
	// 	if(Weapon.bPlayerWantsToShoot)
	// 		LerpSpeed = 15;

	// 	NewHeightOffset = Math::FInterpTo(PreviousRelativeHeightOffset, NewHeightOffset, DeltaTime, LerpSpeed);
	// 	PreviousRelativeHeightOffset = NewHeightOffset;

	// 	AttachLocation = AttachLocation.VectorPlaneProject(Player.MovementWorldUp);
	// 	AttachLocation += Player.MovementWorldUp * NewHeightOffset;
	// 	return AttachLocation;

	// }
};