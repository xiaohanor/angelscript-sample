class UDragonSwordCombatCameraCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::Camera);

	default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSword);
	default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSwordCamera);

	default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSwordCombat);
	default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSwordCombatCamera);

	default DebugCategory = SummitDebugCapabilityTags::DragonSword;

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 110;

	UDragonSwordCombatUserComponent CombatComp;
	UDragonSwordUserComponent SwordComp;
	UCameraSettings PlayerCameraSettings;

	float EndCombatTimer = 0;
	int CurrentSide = 0;
	uint LastModifiedFrame;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CombatComp = UDragonSwordCombatUserComponent::Get(Owner);
		SwordComp = UDragonSwordUserComponent::Get(Owner);
		PlayerCameraSettings = UCameraSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!SwordComp.IsWeaponEquipped())
			return false;

		if(!IsActivelyInCombat())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!SwordComp.IsWeaponEquipped())
			return true;

		if(!IsActivelyInCombat() && EndCombatTimer > DragonSwordCombat::CombatCameraEndDelay)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ApplyCameraSettings(CombatComp.CameraSettings, DragonSwordCombat::CombatCameraBlendInTime, this, SubPriority = 61);
		CurrentSide = -1.0;
		EndCombatTimer = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearCameraSettingsByInstigator(this, DragonSwordCombat::CombatCameraBlendOutTime);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!IsActivelyInCombat())
		{
			EndCombatTimer += DeltaTime;
		}
		else
		{
			EndCombatTimer = 0;
		}
	}

	private bool IsActivelyInCombat() const
	{
		if(CombatComp.HasActiveAttack() && !CombatComp.bInsideSettleWindow)
			return true;

		if(CombatComp.HasPendingAttack())
			return true;

		// if(CombatComp.bInsideSettleWindow)
		// 	return true;

		return false;
	}

	void UpdatePivotOffset(bool bInitial = false)
	{
		if(!CombatComp.PendingAttackData.IsValid() && !CombatComp.ActiveAttackData.IsValid())
			return;

		// This will cause an ensure when applying camera settings since the blend time is above 0.
		if(Time::FrameNumber == LastModifiedFrame + 1)
			return;

		FDragonSwordCombatAttackData AttackData = CombatComp.PendingAttackData.IsValid() ? CombatComp.PendingAttackData : CombatComp.ActiveAttackData;
		
		int NewSide = CurrentSide;

		if(!bInitial && NewSide == CurrentSide)
			return;

		CurrentSide = NewSide;
		PlayerCameraSettings.PivotOffset.Apply(FVector(50.0, CurrentSide == 1 ? CombatComp.CameraRightMaxOffset : CombatComp.CameraLeftMaxOffset, 150.0), this, 1.0);
		LastModifiedFrame = Time::FrameNumber;
	}
}