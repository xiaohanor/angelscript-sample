class UBattlefieldSlowMoGrappleActiveCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ABattlefieldSlowMoGrappleManager GrappleManager;

	float CurrentTimeDilation;
	float TimeDilationTarget = 0.2;
	bool bCanDeactivate = false;
	bool bClearedPOI = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GrappleManager = Cast<ABattlefieldSlowMoGrappleManager>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!GrappleManager.bBeginSlowMo)
			return false;

		if (bCanDeactivate)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (bCanDeactivate)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CurrentTimeDilation = 1.0;
				
		for (AHazePlayerCharacter Player : Game::Players)
			Player.ApplyCameraSettings(GrappleManager.CameraSetting[Player], 5.0, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Time::SetWorldTimeDilation(CurrentTimeDilation);

		for (AHazePlayerCharacter Player : Game::Players)
			Player.ClearCameraSettingsByInstigator(this, 1.5);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!GrappleManager.bGrappleCompleted)
		{
			CurrentTimeDilation = Math::FInterpConstantTo(CurrentTimeDilation, TimeDilationTarget, DeltaTime, 2.5);
			
			for (AHazePlayerCharacter Player : Game::Players)
			{
				FVector LookAt = GrappleManager.GetSplineLocation(Player);
				LookAt += FVector(0,0,0);

				FHazePointOfInterestFocusTargetInfo Target;
				Target.SetFocusToWorldLocation(LookAt);
				FApplyPointOfInterestSettings Settings;
				Settings.bBlockFindAtOtherPlayer = true;
				Settings.Duration = 1.5;
				Player.ApplyPointOfInterest(this, Target, Settings, 4.0);
			}
		}
		else	
		{
			CurrentTimeDilation = Math::FInterpConstantTo(CurrentTimeDilation, 1.0, DeltaTime, 2.5);
			if (CurrentTimeDilation == 1.0)
			{
				bCanDeactivate = true;
			}

			if (!bClearedPOI)
			{
				for (AHazePlayerCharacter Player : Game::Players)
					Player.ClearPointOfInterestByInstigator(this);

				bClearedPOI = true;
			}
		}
		
		Time::SetWorldTimeDilation(CurrentTimeDilation);
		PrintToScreen(f"{CurrentTimeDilation=}");
	}
};