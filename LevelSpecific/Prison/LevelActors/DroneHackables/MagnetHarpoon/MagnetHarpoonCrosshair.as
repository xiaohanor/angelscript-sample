class UMagnetHarpoonCrosshair : UCrosshairWidget
{
	UPROPERTY(BindWidget)
	UImage Crosshair;

	AMagnetHarpoon Harpoon;

	EMagnetHarpoonState LastState;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		BP_OnActivated();
		LastState = EMagnetHarpoonState::Aim;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if(Harpoon.State == EMagnetHarpoonState::Launched)
		{
			if(LastState == EMagnetHarpoonState::Aim)
			{
				LastState = EMagnetHarpoonState::Launched;
				BP_OnShoot();
			}
		}
		else if(Harpoon.State == EMagnetHarpoonState::Attached)
		{
			if(LastState != EMagnetHarpoonState::Attached)
			{
				LastState = EMagnetHarpoonState::Attached;
				BP_OnAttach();
			}
		}
		else if(Harpoon.State == EMagnetHarpoonState::Retracting || Harpoon.State == EMagnetHarpoonState::Aim)
		{
			if(LastState != EMagnetHarpoonState::Aim)
			{
				LastState = EMagnetHarpoonState::Aim;
				BP_OnRetract();
			}
		}
	}

	void Initialize(AMagnetHarpoon InHarpoon)
	{
		Harpoon = InHarpoon;
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnActivated(){}

	UFUNCTION(BlueprintEvent)
	void BP_OnShoot(){}

	UFUNCTION(BlueprintEvent)
	void BP_OnAttach(){}

	UFUNCTION(BlueprintEvent)
	void BP_OnRetract(){}
}