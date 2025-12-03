class UDragonSwordCombatAimCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	
	default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSword);
	default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSwordAim);

	default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSwordCombat);
	default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSwordCombatAim);

	default DebugCategory = SummitDebugCapabilityTags::DragonSword;

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 105;

	UDragonSwordCombatUserComponent CombatComp;

	UPlayerAimingComponent AimComp;
	UPlayerTargetablesComponent TargetablesComp;
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CombatComp = UDragonSwordCombatUserComponent::Get(Owner);
		
		AimComp = UPlayerAimingComponent::Get(Owner);
		TargetablesComp = UPlayerTargetablesComponent::Get(Owner);
		MoveComp = UPlayerMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TargetablesComp.OverrideTargetableAimRay(DragonSwordCombat::TargetableCategory, GetAimingRay());

		if(ShouldDrawWidgets())
		{
			FTargetableWidgetSettings WidgetSettings;
			WidgetSettings.TargetableCategory = DragonSwordCombat::TargetableCategory;
			WidgetSettings.DefaultWidget = CombatComp.TargetableWidget;
			WidgetSettings.MaximumVisibleWidgets = 1;
			WidgetSettings.bOnlyShowWidgetsForPossibleTargets = true;

			TargetablesComp.ShowWidgetsForTargetables(WidgetSettings);
		}

		FTargetableOutlineSettings OutlineSettings;
		OutlineSettings.TargetableCategory = DragonSwordCombat::TargetableCategory;
		OutlineSettings.MaximumOutlinesVisible = -1;
		OutlineSettings.bShowVisibleTargets = true;
		OutlineSettings.bOnlyShowOneTarget = true;
		
		//TargetablesComp.ShowOutlinesForTargetables(OutlineSettings);
	}

	bool ShouldDrawWidgets() const
	{
		return true;
	}

	FAimingRay GetAimingRay() const
	{
		FAimingRay AimRay = AimComp.GetPlayerAimingRay();
		AimRay.Direction = CombatComp.GetMovementDirection(Player.ActorForwardVector);
		
		return AimRay;
	}
}