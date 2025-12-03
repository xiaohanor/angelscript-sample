// class UGravityBladeCombatCameraFollowCapability : UHazePlayerCapability
// {
// 	default CapabilityTags.Add(CapabilityTags::Camera);
// 	default CapabilityTags.Add(CameraTags::CameraControl);
// 	default CapabilityTags.Add(CapabilityTags::GameplayAction);

// 	default TickGroup = EHazeTickGroup::BeforeMovement;
// 	default TickGroupOrder = 1;

// 	UGravityBladeUserComponent BladeComp;
// 	UGravityBladeCombatUserComponent CombatComp;
// 	UCameraUserComponent CameraUserComp;

// 	float TimeOfLastCameraMove = -100.0;

// 	bool bPoi = false;
// 	bool bEnabled = false;
	
// 	UFUNCTION(BlueprintOverride)
// 	void Setup()
// 	{
// 		BladeComp = UGravityBladeUserComponent::Get(Player);
// 		CombatComp = UGravityBladeCombatUserComponent::Get(Player);
// 		CameraUserComp = UCameraUserComponent::Get(Player);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void PreTick(float DeltaTime)
// 	{
// 		if(BladeComp.IsWeaponEquipped() && IsActivelyInCombat())
// 		{
// 			if(!GetAttributeVector2D(AttributeVectorNames::CameraDirection).IsNearlyZero())
// 				TimeOfLastCameraMove = Time::GetGameTimeSeconds();
// 		}
// 		else
// 		{
// 			TimeOfLastCameraMove = -100.0;
// 		}
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	bool ShouldActivate() const
// 	{
// 		if(!bEnabled)
// 			return false;

// 		if(!HasControl())
// 			return false;

// 		if(!BladeComp.IsWeaponEquipped())
// 			return false;

// 		if(!IsActivelyInCombat())
// 			return false;

// 		if(CombatComp.bGloryKillActive)
// 			return false;

// 		if(bPoi && !CombatComp.ActiveAttackData.IsValid())
// 			return false;

// 		if(bPoi && CombatComp.ActiveAttackData.Target == nullptr)
// 			return false;

// 		if(!bPoi && Time::GetGameTimeSeconds() - TimeOfLastCameraMove < GravityBladeCombat::CombatCameraFollowAgainDelay)
// 			return false;

// 		return true;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	bool ShouldDeactivate() const
// 	{
// 		if(!bEnabled)
// 			return true;

// 		if(!HasControl())
// 			return true;

// 		if(!BladeComp.IsWeaponEquipped())
// 			return true;

// 		if(!IsActivelyInCombat())
// 			return true;

// 		if(CombatComp.bGloryKillActive)
// 			return true;

// 		if(bPoi && !CombatComp.ActiveAttackData.IsValid())
// 			return true;

// 		if(bPoi && CombatComp.ActiveAttackData.Target == nullptr)
// 			return true;

// 		if(!bPoi && Time::GetGameTimeSeconds() - TimeOfLastCameraMove < GravityBladeCombat::CombatCameraFollowAgainDelay)
// 			return true;

// 		return false;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated()
// 	{
// 		if(bPoi)
// 		{
// 			FHazePointOfInterestFocusTargetInfo TargetInfo;
// 			TargetInfo.SetFocusToActor(CombatComp.ActiveAttackData.Target.Owner);
// 			FApplyPointOfInterestSettings POISettings;
// 			POISettings.InputPauseTime = 0.5;
// 			Player.ApplyPointOfInterest(this, TargetInfo, POISettings);
// 		}
// 		else
// 		{
// 			Player.BlockCapabilities(CameraTags::CameraControl, this);
// 		}
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated()
// 	{
// 		if(bPoi)
// 		{
// 			Player.ClearPointOfInterestByInstigator(this);
// 		}
// 		else
// 		{
// 			Player.UnblockCapabilities(CameraTags::CameraControl, this);
// 		}
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void TickActive(float DeltaTime)
// 	{
// 		if(bPoi)
// 			return;

// 		FRotator NewRotation = Math::RInterpTo(CameraUserComp.GetDesiredRotation(), Player.ActorRotation + GravityBladeCombat::OffsetDesiredRotationInLeap, DeltaTime, GravityBladeCombat::LeapingFollowCameraInterpSpeed);
// 		CameraUserComp.SetDesiredRotation(NewRotation, this);
// 	}

// 	private bool IsActivelyInCombat() const
// 	{
// 		if(CombatComp.HasActiveAttack() && !CombatComp.bInsideSettleWindow)
// 			return true;

// 		if(CombatComp.HasPendingAttack())
// 			return true;

// 		return false;
// 	}
// }