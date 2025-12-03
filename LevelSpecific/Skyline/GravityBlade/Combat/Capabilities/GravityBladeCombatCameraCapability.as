class UGravityBladeCombatCameraCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::Camera);

	default CapabilityTags.Add(GravityBladeTags::GravityBlade);
	default CapabilityTags.Add(GravityBladeTags::GravityBladeCamera);

	default CapabilityTags.Add(GravityBladeCombatTags::GravityBladeCombat);
	default CapabilityTags.Add(GravityBladeCombatTags::GravityBladeCombatCamera);

	default DebugCategory = GravityBlade::DebugCategory;

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 110;

	UGravityBladeCombatUserComponent CombatComp;
	UGravityBladeUserComponent BladeComp;
	UCameraSettings PlayerCameraSettings;

	float EndCombatTimer = 0;
	int CurrentSide = 0;
	uint LastModifiedFrame;
	float ManualFraction = 0.0;
	float CurrentY = 0.0;
	bool bHasSetCurrentY = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CombatComp = UGravityBladeCombatUserComponent::Get(Owner);
		BladeComp = UGravityBladeUserComponent::Get(Owner);
		PlayerCameraSettings = UCameraSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!BladeComp.IsBladeEquipped())
			return false;

		if(!IsHittingEnemy())
			return false;

		if(CombatComp.bGloryKillActive)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!BladeComp.IsBladeEquipped() && !CombatComp.ThrowBladeData.IsValid())
			return true;

		if(!IsHittingAnything() && EndCombatTimer > GravityBladeCombat::CombatCameraEndDelay)
			return true;

		if(CombatComp.bGloryKillActive)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ApplyCameraSettings(CombatComp.CameraSettings, GravityBladeCombat::CombatCameraBlendInTime, this, SubPriority = 61);
		CurrentSide = -1.0;
		EndCombatTimer = 0;
		ManualFraction = 0.0;
		CurrentY = 0.0;
		bHasSetCurrentY = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearCameraSettingsByInstigator(this, CombatComp.bGloryKillActive ? 0.5 : GravityBladeCombat::CombatCameraBlendOutTime);
		Player.ClearCameraSettingsByInstigator(n"GravityBladeCombatCameraOffset", CombatComp.bGloryKillActive ? 0.5 : GravityBladeCombat::CombatCameraBlendOutTime);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!IsHittingAnything())
		{
			EndCombatTimer += DeltaTime;
		}
		else
		{
			UpdatePivotOffsetContinuous(DeltaTime);
			EndCombatTimer = 0;
		}
	}

	private bool IsHittingEnemy() const
	{
		if(CombatComp.HasActiveAttack() && !CombatComp.bInsideSettleWindow)
		{
			UGravityBladeCombatTargetComponent Target = CombatComp.ActiveAttackData.GetTarget();
			if (Target != nullptr && Target.IsEnemy())
				return true;
		}

		if(CombatComp.HasPendingAttack())
		{
			UGravityBladeCombatTargetComponent Target = CombatComp.PendingAttackData.GetTarget();
			if (Target != nullptr && Target.IsEnemy())
				return true;
		}

		return false;
	}

	private bool IsHittingAnything() const
	{
		if(CombatComp.HasActiveAttack() && !CombatComp.bInsideSettleWindow)
			return true;

		if(CombatComp.HasPendingAttack())
			return true;

		return false;
	}

	// void UpdatePivotOffset(bool bInitial = false)
	// {
	// 	if(!CombatComp.PendingAttackData.IsValid() && !CombatComp.ActiveAttackData.IsValid())
	// 		return;

	// 	// This will cause an ensure when applying camera settings since the blend time is above 0.
	// 	if(Time::FrameNumber == LastModifiedFrame + 1)
	// 		return;

	// 	FGravityBladeCombatAttackData AttackData = CombatComp.PendingAttackData.IsValid() ? CombatComp.PendingAttackData : CombatComp.ActiveAttackData;
		
	// 	int NewSide = CurrentSide;

	// 	if(AttackData.Target != nullptr)
	// 	{
	// 		FVector2D ScreenPos;
	// 		SceneView::ProjectWorldToViewpointRelativePosition(Player, AttackData.Target.WorldLocation, ScreenPos);
	// 		NewSide = Math::Sign(ScreenPos.X - 0.5);

	// 		if(!bInitial && Math::Abs(ScreenPos.X - 0.5) < 0.125)
	// 			return;
	// 	}

	// 	if(!bInitial && NewSide == CurrentSide)
	// 		return;

	// 	CurrentSide = NewSide;
	// 	PlayerCameraSettings.PivotOffset.Apply(FVector(50.0, CurrentSide == 1 ? CombatComp.CameraRightMaxOffset : CombatComp.CameraLeftMaxOffset, 150.0), this, 1.0);
	// 	LastModifiedFrame = Time::FrameNumber;
	// }

	void UpdatePivotOffsetContinuous(float DeltaTime)
	{
		if(!CombatComp.PendingAttackData.IsValid() && !CombatComp.ActiveAttackData.IsValid())
			return;

		FGravityBladeCombatAttackData AttackData = CombatComp.PendingAttackData.IsValid() ? CombatComp.PendingAttackData : CombatComp.ActiveAttackData;

		if(AttackData.Target == nullptr)
			return;

		if(AttackData.IsRushAttack())
			return;

		FVector2D ScreenPos;
		SceneView::ProjectWorldToViewpointRelativePosition(Player, AttackData.Target.WorldLocation, ScreenPos);

		float ClampedX = Math::Clamp(ScreenPos.X, 0.0, 1.0);

		float TargetY = Math::Lerp(CombatComp.CameraLeftMaxOffset, CombatComp.CameraRightMaxOffset, ClampedX);

		if(!bHasSetCurrentY)
		{
			bHasSetCurrentY = true;
			CurrentY = TargetY;
		}

		CurrentY = Math::FInterpTo(CurrentY, TargetY, DeltaTime, 7.0);

		ManualFraction = Math::FInterpTo(ManualFraction, 1.0, DeltaTime, 2.0);
		//PlayerCameraSettings.PivotOffset.Apply(FVector(50.0, CurrentY, 150.0), this, 0.0);
		PlayerCameraSettings.CameraOffset.ApplyAsAdditive(FVector(0.0, CurrentY, 0.0), n"GravityBladeCombatCameraOffset", 0.0);
		Player.ApplyManualFractionToCameraSettings(ManualFraction, n"GravityBladeCombatCameraOffset");
	}
}