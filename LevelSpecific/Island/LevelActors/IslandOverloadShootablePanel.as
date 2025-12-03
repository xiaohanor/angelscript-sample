event void FAIslandOverloadShootablePanelSignature();

enum EIslandOverloadShootablePanelVisualState
{
	Disabled,
	Active,
	Charging,
	Completed
}

class AIslandOverloadShootablePanel : AHazeActor
{
	UPROPERTY()
	FAIslandGrenadeLockListenerSignature OnCompleted;

	UPROPERTY()
	FAIslandGrenadeLockListenerSignature OnImpact;

	UPROPERTY()
	FAIslandGrenadeLockListenerSignature OnOvercharged;
	
	UPROPERTY()
	FAIslandGrenadeLockListenerSignature OnDischarging;

	UPROPERTY()
	FAIslandGrenadeLockListenerSignature OnReset;

	UPROPERTY(DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = "Root")
	UStaticMeshComponent ShootMesh;
	default ShootMesh.bBlockVisualsOnDisable = false;

	UPROPERTY(DefaultComponent)
	UIslandRedBlueTargetableComponent TargetComp;

	UPROPERTY(DefaultComponent)
	UIslandRedBlueImpactOverchargeResponseComponent OverchargeComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.0;

	UPROPERTY(EditAnywhere)
	UIslandRedBlueImpactOverchargeResponseComponentSettingsDataAsset MioSettings;

	UPROPERTY(EditAnywhere)
	UIslandRedBlueImpactOverchargeResponseComponentSettingsDataAsset ZoeSettings;

	UPROPERTY(EditAnywhere)
	AIslandRedBlueImpactOverchargeResponseDisplay DisplayRef;

	UPROPERTY(DefaultComponent)
	USceneComponent DisplayComponent;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(Category = "Border Materials")
	UMaterialInterface MioActiveBorderMaterial;

	UPROPERTY(Category = "Border Materials")
	UMaterialInterface ZoeActiveBorderMaterial;

	UPROPERTY(Category = "Border Materials")
	UMaterialInterface MioDisabledBorderMaterial;

	UPROPERTY(Category = "Border Materials")
	UMaterialInterface ZoeDisabledBorderMaterial;

	UPROPERTY(Category = "Border Materials")
	UMaterialInterface MioCompletedBorderMaterial;

	UPROPERTY(Category = "Border Materials")
	UMaterialInterface ZoeCompletedBorderMaterial;

	UPROPERTY(Category = "Display Bar Materials")
	UMaterialInterface MioDisabledDisplayBarMaterial;

	UPROPERTY(Category = "Display Bar Materials")
	UMaterialInterface ZoeDisabledDisplayBarMaterial;

	UPROPERTY(Category = "Display Bar Materials")
	UMaterialInterface MioCompletedDisplayBarMaterial;

	UPROPERTY(Category = "Display Bar Materials")
	UMaterialInterface ZoeCompletedDisplayBarMaterial;

	UPROPERTY(Category = "Display Bar Materials")
	UMaterialInterface MioActiveDisplayBarMaterial;

	UPROPERTY(Category = "Display Bar Materials")
	UMaterialInterface ZoeActiveDisplayBarMaterial;

	UPROPERTY(Category = "Display Bar Materials")
	UMaterialInterface MioChargingDisplayBarMaterial;

	UPROPERTY(Category = "Display Bar Materials")
	UMaterialInterface ZoeChargingDisplayBarMaterial;

	UPROPERTY(Category = "Optional Display Materials")
	UMaterialInterface OptionalDisplayCompletedMaterial;

	UPROPERTY(EditInstanceOnly)
	EHazePlayer UsableByPlayer = EHazePlayer::Mio;

	UPROPERTY(EditAnywhere)
	bool bStartDisabled;

	UPROPERTY(EditAnywhere)
	bool bResetChargeOnOvercharge = false;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bResetChargeOnOvercharge", EditConditionHides))
	float ImpactCooldownAfterResetCharge = 0.15;

	AIslandOverloadPanelListener PanelListener;
	UMaterialInstanceDynamic Internal_DisplayBarDynamicMaterial;
	UMaterialInstanceDynamic Internal_BorderDynamicMaterial;
	AHazePlayerCharacter LastImpactPlayer;
	uint LastImpactFrame;
	float LastImpactTime;
	bool bIsDisabled = false;
	bool bIsCompleted = false;

	UPROPERTY(NotVisible, BlueprintReadOnly)
	const int DisplayBarMaterialIndex = 0;

	UPROPERTY(NotVisible, BlueprintReadOnly)
	const int BorderMaterialIndex = 1;

	EIslandOverloadShootablePanelVisualState CurrentVisualState = EIslandOverloadShootablePanelVisualState::Active;
	FLinearColor OriginalBorderColor;
	FLinearColor CurrentBorderColor;

	const float ImpactBorderEmissiveDuration = 0.2;
	const float MaxBorderEmissiveMultiplier = 50.0;
	
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(UsableByPlayer == EHazePlayer::Mio)
		{
			OverchargeComp.SettingsDataAsset_Property = MioSettings;
			SetDisplayBarMaterial(MioActiveDisplayBarMaterial, true);
			SetBorderMaterial(MioActiveBorderMaterial, true);
		}
		else
		{
			OverchargeComp.SettingsDataAsset_Property = ZoeSettings;
			SetDisplayBarMaterial(ZoeActiveDisplayBarMaterial, true);
			SetBorderMaterial(ZoeActiveBorderMaterial, true);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CreateBorderDynamicMaterial(false);
		CreateDisplayBarDynamicMaterial();
		OriginalBorderColor = BorderDynamicMaterial.GetVectorParameterValue(n"Global_EmissiveTint");
		CurrentBorderColor = OriginalBorderColor;

		SetActorControlSide(Game::GetPlayer(UsableByPlayer));
		bIsDisabled = false;

		if(DisplayRef != nullptr)
		{
			DisplayRef.Display.CompletedMaterial = OptionalDisplayCompletedMaterial;
			OverchargeComp.OptionalDisplay = DisplayRef;
		}

		OverchargeComp.OnImpactEvent.AddUFunction(this, n"HandleImpact");
		OverchargeComp.OnFullCharge.AddUFunction(this, n"HandleFullAlpha");
		OverchargeComp.OnStartDischarging.AddUFunction(this, n"HandleDischarging");
		OverchargeComp.OnZeroCharge.AddUFunction(this, n"HandleOnZeroCharge");

		OverchargeComp.BlockImpactForPlayer(Game::GetOtherPlayer(UsableByPlayer), this);
		TargetComp.DisableForPlayer(Game::GetOtherPlayer(UsableByPlayer), this);

		if(bStartDisabled)
		{
			DisablePanel();
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		devCheck(!bIsDisabled, "Tick ran even though panel should be disabled");

		if(!bIsCompleted)
			DisplayBarDynamicMaterial.SetScalarParameterValue(n"FillPercentage", OverchargeComp.ChargeAlpha);

		SetBorderEmissiveColor(GetBorderEmissiveColor(true, DeltaTime));

		if(CurrentVisualState == EIslandOverloadShootablePanelVisualState::Active && OverchargeComp.ChargeAlpha > 0.0)
		{
			SetPanelVisualState(EIslandOverloadShootablePanelVisualState::Charging);
		}
		else if(CurrentVisualState == EIslandOverloadShootablePanelVisualState::Charging && OverchargeComp.ChargeAlpha == 0.0)
		{
			SetPanelVisualState(EIslandOverloadShootablePanelVisualState::Active);
		}

#if TEST
		TEMPORAL_LOG(this)
			.Value("Current Visual State", CurrentVisualState)
		;
#endif
	}

	UFUNCTION()
	void HandleFullAlpha(bool bWasOvercharged)
	{
		if(bWasOvercharged)
			return;

		if(OverchargeComp.Settings.bBlockDischargeWhenFull || OverchargeComp.Settings.DischargeSpeed == 0.0)
		{
			UIslandOverloadShootablePanelEffectHandler::Trigger_OnHoldFullyCharged(this);
			SetCompleted();
		}
		else
		{
			UIslandOverloadShootablePanelEffectHandler::Trigger_OnFullyCharged(this);
		}

		if(CameraShake != nullptr)
			Game::GetPlayer(UsableByPlayer).PlayCameraShake(CameraShake, this, 1.0);

		OnOvercharged.Broadcast();

		BP_HandleFullAlpha();

		if(PanelListener != nullptr)
		{
			PanelListener.CheckChildren();
		}

		if(bResetChargeOnOvercharge)
		{
			ResetAndCooldownImpacts();
		}
	}

	void ResetAndCooldownImpacts()
	{
		OverchargeComp.ResetChargeAlpha(this);

		if(ImpactCooldownAfterResetCharge > 0.0)
		{
			BlockImpacts();
			Timer::SetTimer(this, n"UnblockImpacts", ImpactCooldownAfterResetCharge);
		}
	}

	UFUNCTION()
	void HandleImpact(FIslandRedBlueImpactResponseParams ImpactData)
	{
		if(bIsDisabled)
			return;

		OnImpact.Broadcast();

		LastImpactTime = Time::GetGameTimeSeconds();
		LastImpactFrame = Time::FrameNumber;
		LastImpactPlayer = ImpactData.Player;

		if(IslandRedBlueWeapon::PlayerCanHitOverchargeComponent(ImpactData.Player, OverchargeComp.OverchargeColor))
		{
			UIslandOverloadShootablePanelEffectHandler::Trigger_OnGoodProjectileHit(this);

			if(HasControl() && OverchargeComp.PreviousChargeAlpha == 0.0)
				CrumbOnStartCharging();
		}
		else if(OverchargeComp.Settings.bDischargeOnWrongColor)
		{
			UIslandOverloadShootablePanelEffectHandler::Trigger_OnBadProjectileHit(this);
		}

		BP_HandleImpact();
	}

	void SetPanelVisualState(EIslandOverloadShootablePanelVisualState State)
	{
		if(CurrentVisualState == State)
			return;

		switch(State)
		{
			case EIslandOverloadShootablePanelVisualState::Disabled:
			{
				SetDisplayBarMaterial(UsableByPlayer == EHazePlayer::Mio ? MioDisabledDisplayBarMaterial : ZoeDisabledDisplayBarMaterial);
				SetBorderMaterial(UsableByPlayer == EHazePlayer::Mio ? MioDisabledBorderMaterial : ZoeDisabledBorderMaterial);
				break;
			}
			case EIslandOverloadShootablePanelVisualState::Active:
			{
				SetDisplayBarMaterial(UsableByPlayer == EHazePlayer::Mio ? MioActiveDisplayBarMaterial : ZoeActiveDisplayBarMaterial);
				SetBorderMaterial(UsableByPlayer == EHazePlayer::Mio ? MioActiveBorderMaterial : ZoeActiveBorderMaterial);
				break;
			}
			case EIslandOverloadShootablePanelVisualState::Charging:
			{
				SetDisplayBarMaterial(UsableByPlayer == EHazePlayer::Mio ? MioChargingDisplayBarMaterial : ZoeChargingDisplayBarMaterial);
				SetBorderMaterial(UsableByPlayer == EHazePlayer::Mio ? MioActiveBorderMaterial : ZoeActiveBorderMaterial);
				break;
			}
			case EIslandOverloadShootablePanelVisualState::Completed:
			{
				SetDisplayBarMaterial(UsableByPlayer == EHazePlayer::Mio ? MioCompletedDisplayBarMaterial : ZoeCompletedDisplayBarMaterial);
				SetBorderMaterial(UsableByPlayer == EHazePlayer::Mio ? MioCompletedBorderMaterial : ZoeCompletedBorderMaterial);
				break;
			}
		}

		CurrentVisualState = State;
	}

	UFUNCTION()
	void SetCompleted()
	{
		bIsCompleted = true;
		OnCompleted.Broadcast();
		SetPanelVisualState(EIslandOverloadShootablePanelVisualState::Completed);
		SetBorderEmissiveColor(GetBrightestBorderEmissiveColor());
		SetActorTickEnabled(false);
		BlockImpacts();

		if(DisplayRef != nullptr)
		{
			OverchargeComp.OptionalDisplay = nullptr;
			DisplayRef.Display.SetCompleted();
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnStartCharging()
	{
		UIslandOverloadShootablePanelEffectHandler::Trigger_OnStartCharging(this);
	}

	UFUNCTION()
	private void BlockImpacts()
	{
		TargetComp.DisableForPlayer(Game::GetPlayer(UsableByPlayer), this);
		OverchargeComp.BlockImpactForPlayer(Game::GetPlayer(UsableByPlayer), this);
	}

	UFUNCTION()
	private void UnblockImpacts()
	{
		TargetComp.EnableForPlayer(Game::GetPlayer(UsableByPlayer), this);
		OverchargeComp.UnblockImpactForPlayer(Game::GetPlayer(UsableByPlayer), this);
	}

	UFUNCTION()
	void HandleDischarging(bool bCurrentlyAtFullCharge)
	{
		if(!bCurrentlyAtFullCharge)
			return;

		if(!bIsDisabled)
			UIslandOverloadShootablePanelEffectHandler::Trigger_OnStartDischarging(this);

		OnDischarging.Broadcast();
	}

	UFUNCTION()
	void HandleOnZeroCharge(bool bWasOvercharged)
	{
		if(!bIsDisabled)
			UIslandOverloadShootablePanelEffectHandler::Trigger_OnChargeReset(this);

		if(bWasOvercharged)
		{
			OnReset.Broadcast();

			if (bIsDisabled)
				return;
			
			if(PanelListener != nullptr && PanelListener.bResettable && !PanelListener.bWithinFinishedScope)
			{
				PanelListener.bFinished = false;
				PanelListener.CheckChildren();
			}
		}
	}

	UFUNCTION()
	void DisablePanel()
	{
		if(bIsCompleted)
			return;
		
		BorderDynamicMaterial.SetVectorParameterValue(n"Global_EmissiveTint", OriginalBorderColor);
		SetPanelVisualState(EIslandOverloadShootablePanelVisualState::Disabled);
		SetActorTickEnabled(false);
		BlockImpacts();

		DisplayBarDynamicMaterial.SetScalarParameterValue(n"FillPercentage", 0.0);
		bIsDisabled = true;

		if(DisplayRef != nullptr)
		{
			OverchargeComp.OptionalDisplay = nullptr;
			DisplayRef.Display.SetFillPercentage(0.0);
		}
	}

	UFUNCTION()
	void EnablePanel()
	{
		if(bIsCompleted)
			return;

		SetPanelVisualState(EIslandOverloadShootablePanelVisualState::Active);
		SetActorTickEnabled(true);
		UnblockImpacts();
		bIsDisabled = false;

		if(DisplayRef != nullptr)
		{
			OverchargeComp.OptionalDisplay = DisplayRef;
			DisplayRef.SetActorHiddenInGame(false);
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_HandleImpact()
	{}

	UFUNCTION(BlueprintEvent)
	void BP_HandleFullAlpha()
	{}

	// Will get the current charge alpha of how charged this overload shootable panel is.
	UFUNCTION(BlueprintPure)
	float GetCurrentCharge() const
	{
		if(bIsDisabled)
			return 1.0;

		return OverchargeComp.ChargeAlpha;
	}

	// Will return 1 if the panel was shot and charged this frame, 0 if the charge didn't change.
	// -1 if it is currently discharging
	UFUNCTION(BlueprintPure)
	int GetCurrentChargeDirection() const
	{
		if(bIsDisabled)
			return 0;

		if(OverchargeComp.IsDischarging())
			return -1;

		if(LastImpactFrame == Time::FrameNumber)
		{
			if(IslandRedBlueWeapon::PlayerCanHitOverchargeComponent(LastImpactPlayer, OverchargeComp.OverchargeColor))
				return 1;
			else if(OverchargeComp.Settings.bDischargeOnWrongColor)
				return -1;
		}

		return 0;
	}

	UFUNCTION(BlueprintPure)
	bool IsOvercharged() const
	{
		return OverchargeComp.IsOvercharged();
	}

	FLinearColor GetBorderEmissiveColor(bool bLerp = false, float DeltaTime = 0.0)
	{
		// The below code is if we want the lights on the edge to respond to bullet impacts
		// FLinearColor HSVColor = OriginalBorderColor.LinearRGBToHSV();
		// float SinceImpact = Time::GetGameTimeSince(LastImpactTime);
		// HSVColor.B *= Math::Lerp(MaxBorderEmissiveMultiplier, 1.0, Math::Saturate(SinceImpact / ImpactBorderEmissiveDuration));
		// return HSVColor.HSVToLinearRGB();

		if(!bLerp)
			return CurrentBorderColor;

		FLinearColor TargetColor = OriginalBorderColor;
		if(IsOvercharged())
		{
			TargetColor = GetBrightestBorderEmissiveColor();
		}
		
		CurrentBorderColor = Math::CInterpTo(CurrentBorderColor, TargetColor, DeltaTime, 25.0);
		return CurrentBorderColor;
	}

	FLinearColor GetBrightestBorderEmissiveColor()
	{
		FLinearColor HSVColor = OriginalBorderColor.LinearRGBToHSV();
		HSVColor.B *= MaxBorderEmissiveMultiplier;
		return HSVColor.HSVToLinearRGB();
	}

	void SetBorderEmissiveColor(FLinearColor Color)
	{
		BorderDynamicMaterial.SetVectorParameterValue(n"Global_EmissiveTint", Color);
	}

	void SetDisplayBarMaterial(UMaterialInterface Material, bool bConstructionScript = false)
	{
		ShootMesh.SetMaterial(DisplayBarMaterialIndex, Material);

		if(!bConstructionScript)
			CreateDisplayBarDynamicMaterial();
	}

	void SetBorderMaterial(UMaterialInterface Material, bool bConstructionScript = false)
	{
		ShootMesh.SetMaterial(BorderMaterialIndex, Material);

		if((Material == MioActiveBorderMaterial || Material == ZoeActiveBorderMaterial) && !bConstructionScript)
			CreateBorderDynamicMaterial();
	}

	private void CreateDisplayBarDynamicMaterial()
	{
		Internal_DisplayBarDynamicMaterial = ShootMesh.CreateDynamicMaterialInstance(DisplayBarMaterialIndex);
		Internal_DisplayBarDynamicMaterial.SetScalarParameterValue(n"FillPercentage", OverchargeComp.ChargeAlpha);
	}

	private void CreateBorderDynamicMaterial(bool bSetEmissiveColor = true)
	{
		Internal_BorderDynamicMaterial = ShootMesh.CreateDynamicMaterialInstance(BorderMaterialIndex);

		if(bSetEmissiveColor)
			Internal_BorderDynamicMaterial.SetVectorParameterValue(n"Global_EmissiveTint", GetBorderEmissiveColor());
	}

	UMaterialInstanceDynamic GetDisplayBarDynamicMaterial() property
	{
		if(Internal_DisplayBarDynamicMaterial == nullptr)
			CreateDisplayBarDynamicMaterial();

		return Internal_DisplayBarDynamicMaterial;
	}

	UMaterialInstanceDynamic GetBorderDynamicMaterial() property
	{
		if(Internal_BorderDynamicMaterial == nullptr)
			CreateBorderDynamicMaterial();

		return Internal_BorderDynamicMaterial;
	}
}

UCLASS(Abstract)
class UIslandOverloadShootablePanelEffectHandler : UHazeEffectEventHandler
{
	// Triggers when a projectile of the same color as the panel hits.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGoodProjectileHit() {}

	// Triggers when a projectile of the opposite color as the panel hits.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBadProjectileHit() {}

	// Triggers when the charge goes from 0 to above 0.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartCharging() {}

	// Triggers when the charge starts moving towards 0.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartDischarging() {}

	// Triggers when the charge goes from above 0 to 0.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnChargeReset() {}

	// Triggers when the charge goes from below 1 to 1 and it will eventually discharge.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFullyCharged() {}

	// Triggers when the charge goes from below 1 to 1 and it will stay fully charged forever.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHoldFullyCharged() {}
}