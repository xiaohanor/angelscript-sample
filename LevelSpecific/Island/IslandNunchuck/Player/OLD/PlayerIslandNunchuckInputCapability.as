

// class UPlayerIslandNunchuckInputCapability : UHazeCapability
// {
// 	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	
// 	default CapabilityTags.Add(n"ScifiMelee");

// 	default CapabilityTags.Add(BlockedWhileIn::WallRun);
// 	default CapabilityTags.Add(BlockedWhileIn::WallScramble);
// 	default CapabilityTags.Add(BlockedWhileIn::Ladder);

// 	default DebugCategory = n"ScifiMelee";
	
// 	default TickGroup = EHazeTickGroup::Input;

// 	UPlayerIslandNunchuckUserComponent MeleeComp;
// 	UPlayerMovementComponent MoveComp;
// 	float LastBlockedTime = 0;


// 	UFUNCTION(BlueprintOverride)
// 	void Setup()
// 	{
// 		MeleeComp = UPlayerIslandNunchuckUserComponent::Get(Owner);
// 		MoveComp = UPlayerMovementComponent::Get(Owner);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	bool ShouldActivate() const
// 	{
// 		if(!MeleeComp.HasWeaponEquiped())
// 			return false;

// 		// if(MoveComp.IsInBlockedActionWindow())
// 		// 	return false;

// 		if(IsActioning(ActionNames::PrimaryLevelAbility))
// 			return true;
		
// 		if(WasActionStartedDuringTime(ActionNames::PrimaryLevelAbility, 0.2))
// 			return true;

// 		return false;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	bool ShouldDeactivate() const
// 	{
// 		if(!MeleeComp.HasWeaponEquiped())
// 			return true;

// 		// if(MoveComp.IsInBlockedActionWindow())
// 		// 	return true;

// 		if(IsActioning(ActionNames::PrimaryLevelAbility))
// 			return false;

// 		return true;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated()
// 	{
// 		MeleeComp.bHasHoldInput = true;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated()
// 	{
// 		MeleeComp.bHasPressInput = false;
// 		MeleeComp.bHasHoldInput = false;
// 		MeleeComp.PerformedInputTime = 0;
// 	}

// 	// UFUNCTION(BlueprintOverride)
// 	// void PreTick(float DeltaTime)
// 	// {
// 	// 	float WindowMin = 0, WindowMax = 0;
// 	// 	MeleeComp.GetStandardMoveComboWindow(WindowMin, WindowMax);
// 	// 	PrintToScreen("ComboWindow | Min: " + WindowMin + " Max: " + WindowMax + " | Time: " + MeleeComp.CurrentActiveMoveTime);

// 	// 	if(MeleeComp.IsInStandardMoveComboWindow())
// 	// 		PrintFromObject(this, "COMBO!!");

// 	// }

// 	UFUNCTION(BlueprintOverride)
// 	void TickActive(float DeltaTime)
// 	{
// 		MeleeComp.bHasInput = WasActionStarted(ActionNames::PrimaryLevelAbility);
// 		MeleeComp.bHasHoldInput = true;
// 		MeleeComp.bHasPressInput = MeleeComp.bHasInput;	
// 		MeleeComp.PerformedInputTime += DeltaTime;

// 		if(MeleeComp.CurrentMoveType != EPlayerScifiMeleeMoveType::MAX)
// 		{
// 			// if(MeleeComp.CurrentMoveType != EPlayerScifiMeleeMoveType::Charge)
// 			// {
// 			// 	// // We are not in a charge window so we cant press the charge button
// 			// 	// if(MeleeComp.CurrentActiveMoveTime < MeleeComp.CurrentActiveMoveTimeMax - MeleeComp.DefaultIntoChargeComboWindow)
// 			// 	// 	MeleeComp.PerformedInputTime = 0;	
// 			// }
			
// 			// We are not in a combo window so we cant press the input button
// 			if(!MeleeComp.IsInStandardMoveComboWindow())
// 			{
// 				MeleeComp.bHasPressInput = false;

// 				// We are not in the combo window so we cant activate the charge yet
// 				if(MeleeComp.CurrentMoveType != EPlayerScifiMeleeMoveType::Charge 
// 					&& MeleeComp.PerformedInputTime >= MeleeComp.TriggerChargeWindow
// 					&& MeleeComp.CurrentActiveMoveTime > MeleeComp.TriggerChargeWindow + DeltaTime)
// 					{
// 						MeleeComp.bHasHoldInput = false;
// 					}
// 			}		
// 		}	
// 	}

// };