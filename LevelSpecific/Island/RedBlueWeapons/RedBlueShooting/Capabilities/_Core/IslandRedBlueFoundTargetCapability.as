class UIslandRedBlueFoundTargetCapability : UHazePlayerCapability
{
	UPlayerAimingComponent AimComp;
	UIslandRedBlueWeaponUserComponent WeaponUserComp;
	UPlayerTargetablesComponent TargetablesComp;

	UIslandRedBlueTargetableComponent CurrentTargetable;
	UIslandRedBlueAimCrosshairWidget Crosshair;

	AIslandOverloadShootablePanel OverloadPanel;
	UIslandForceFieldStateComponent ForceFieldState;
	bool bLookingAtForceField = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AimComp = UPlayerAimingComponent::Get(Player);
		WeaponUserComp = UIslandRedBlueWeaponUserComponent::Get(Player);
		TargetablesComp = UPlayerTargetablesComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FIslandRedBlueFoundTargetActivatedParams& Params) const
	{
		if(!AimComp.IsAiming(WeaponUserComp))
			return false;

		auto TempCrosshair = Cast<UIslandRedBlueAimCrosshairWidget>(
			AimComp.GetCrosshairWidget(WeaponUserComp));

		if(TempCrosshair == nullptr)
			return false;

		auto Targetable = TargetablesComp.GetPrimaryTarget(UIslandRedBlueTargetableComponent);

		if(Targetable == nullptr)
			return false;

		Params.Targetable = Targetable;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!AimComp.IsAiming(WeaponUserComp))
			return true;

		auto Targetable = TargetablesComp.GetPrimaryTarget(UIslandRedBlueTargetableComponent);

		if(Targetable == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FIslandRedBlueFoundTargetActivatedParams Params)
	{
		Crosshair = Cast<UIslandRedBlueAimCrosshairWidget>(
			AimComp.GetCrosshairWidget(WeaponUserComp));
		StartLooking(Params.Targetable);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		StopLooking();
	}

	UFUNCTION()
	private void OnCompletedOverloadPanel()
	{
		if(Crosshair != nullptr)
			Crosshair.OnCompleteOverloadPanel(OverloadPanel);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		auto Targetable = TargetablesComp.GetPrimaryTarget(UIslandRedBlueTargetableComponent);

		if(Targetable != CurrentTargetable)
		{
			ChangeTarget(Targetable);
		}

		if(ForceFieldState != nullptr && bLookingAtForceField != ForceFieldState.IsActive())
		{
			bLookingAtForceField = ForceFieldState.IsActive();
			if(Crosshair != nullptr)
			{
				if(bLookingAtForceField)
					Crosshair.OnStartLookingAtForceField(ForceFieldState.bForceFieldIsOnEnemy);
				else
					Crosshair.OnStopLookingAtForceField(ForceFieldState.bForceFieldIsOnEnemy);
			}
		}
	}

	void ChangeTarget(UIslandRedBlueTargetableComponent NewTarget)
	{
		StopLooking();
		StartLooking(NewTarget);
	}

	void StartLooking(UIslandRedBlueTargetableComponent Target)
	{
		CurrentTargetable = Target;

		if(Crosshair != nullptr)
			Crosshair.OnStartLookingAtTarget(CurrentTargetable);

		OverloadPanel = Cast<AIslandOverloadShootablePanel>(CurrentTargetable.Owner);
		if(OverloadPanel != nullptr)
		{
			OverloadPanel.OnCompleted.AddUFunction(this, n"OnCompletedOverloadPanel");

			if(Crosshair != nullptr)
				Crosshair.OnStartLookingAtOverloadPanel(OverloadPanel);
		}

		ForceFieldState = UIslandForceFieldStateComponent::Get(CurrentTargetable.Owner);
		if(ForceFieldState != nullptr)
		{
			bLookingAtForceField = ForceFieldState.IsActive();
			if(bLookingAtForceField)
			{
				if(Crosshair != nullptr)
					Crosshair.OnStartLookingAtForceField(ForceFieldState.bForceFieldIsOnEnemy);
			}
		}
	}

	void StopLooking()
	{
		if(Crosshair != nullptr)
			Crosshair.OnStopLookingAtTarget(CurrentTargetable);

		if(OverloadPanel != nullptr)
		{
			OverloadPanel.OnCompleted.Unbind(this, n"OnCompletedOverloadPanel");

			if(Crosshair != nullptr)
				Crosshair.OnStopLookingAtOverloadPanel(OverloadPanel);

			OverloadPanel = nullptr;
		}

		if(ForceFieldState != nullptr)
		{
			if(bLookingAtForceField)
			{
				if(Crosshair != nullptr)
					Crosshair.OnStopLookingAtForceField(ForceFieldState.bForceFieldIsOnEnemy);

				bLookingAtForceField = false;
			}

			ForceFieldState = nullptr;
		}

		CurrentTargetable = nullptr;
	}
}

struct FIslandRedBlueFoundTargetActivatedParams
{
	UIslandRedBlueTargetableComponent Targetable;
}