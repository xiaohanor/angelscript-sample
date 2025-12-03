class UGravityBladeCombatAimCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	
	default CapabilityTags.Add(GravityBladeTags::GravityBlade);
	default CapabilityTags.Add(GravityBladeTags::GravityBladeWield);
	default CapabilityTags.Add(GravityBladeTags::GravityBladeAim);

	default CapabilityTags.Add(GravityBladeCombatTags::GravityBladeCombat);
	default CapabilityTags.Add(GravityBladeCombatTags::GravityBladeCombatAim);

	// Contextual move blocks
	default CapabilityTags.Add(BlockedWhileIn::Ladder);
	default CapabilityTags.Add(BlockedWhileIn::Grapple);
	default CapabilityTags.Add(BlockedWhileIn::GrappleEnter);
	default CapabilityTags.Add(BlockedWhileIn::LedgeGrab);
	default CapabilityTags.Add(BlockedWhileIn::LedgeMantle);
	default CapabilityTags.Add(BlockedWhileIn::Perch);
	default CapabilityTags.Add(BlockedWhileIn::PerchSpline);
	default CapabilityTags.Add(BlockedWhileIn::PoleClimb);
	default CapabilityTags.Add(BlockedWhileIn::Skydive);
	default CapabilityTags.Add(BlockedWhileIn::Slide);
	default CapabilityTags.Add(BlockedWhileIn::Swing);
	default CapabilityTags.Add(BlockedWhileIn::Vault);
	default CapabilityTags.Add(BlockedWhileIn::WallRun);
	default CapabilityTags.Add(BlockedWhileIn::WallScramble);
	default CapabilityTags.Add(BlockedWhileIn::Swimming);

	default DebugCategory = GravityBlade::DebugCategory;

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 105;

	UGravityBladeCombatUserComponent CombatComp;

	UPlayerAimingComponent AimComp;
	UPlayerTargetablesComponent TargetablesComp;
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CombatComp = UGravityBladeCombatUserComponent::Get(Owner);
		
		AimComp = UPlayerAimingComponent::Get(Owner);
		TargetablesComp = UPlayerTargetablesComponent::Get(Owner);
		MoveComp = UPlayerMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TargetablesComp.OverrideTargetableAimRay(GravityBladeCombat::TargetableCategory, GetAimingRay());

		if(ShouldDrawWidgets())
		{
			FTargetableWidgetSettings WidgetSettings;
			WidgetSettings.TargetableCategory = GravityBladeCombat::TargetableCategory;
			WidgetSettings.DefaultWidget = CombatComp.TargetableWidget;

			TargetablesComp.ShowWidgetsForTargetables(WidgetSettings);
		}
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		// FTargetableOutlineSettings OutlineSettings;
		// OutlineSettings.TargetableCategory = GravityBladeCombat::TargetableCategory;
		// OutlineSettings.MaximumOutlinesVisible = -1;
		// OutlineSettings.bShowVisibleTargets = true;
		// if (IsBlocked())
		// 	OutlineSettings.bAllowPrimaryTargetOutline = false;
		
		// TargetablesComp.ShowOutlinesForTargetables(OutlineSettings);
	}

	bool ShouldDrawWidgets() const
	{
		return true;
	}

	FAimingRay GetAimingRay() const
	{
		FAimingRay AimRay = AimComp.GetPlayerAimingRay();
		if(MoveComp.IsInAir())
		{
			AimRay.Direction = CombatComp.GetMovementDirection(AimRay.Direction);
		}
		else
		{
			if(CombatComp.HasActiveAttack())
				AimRay.Direction = CombatComp.GetMovementDirection(Player.ActorForwardVector);
			else
				AimRay.Direction = CombatComp.GetMovementDirection(AimRay.Direction);
		}

		return AimRay;
	}
}

UCLASS(Abstract)
class UGravityBladeHittableTargetWidget : UTargetableWidget
{
	UPROPERTY(BindWidget)
	UWidget MainContainer;
	UPROPERTY(BindWidget)
	UImage Circle;

	UPROPERTY(BindWidgetAnim)
	UWidgetAnimation DotEnter;
	UPROPERTY(BindWidgetAnim)
	UWidgetAnimation Ready;

	float AnimTime = 0;
	bool bPlayedReadyAnim = false;

	UFUNCTION(BlueprintOverride)
	void OnAdded()
	{
		MainContainer.SetRenderOpacity(0.0);
		bPlayedReadyAnim = false;
		PlayAnimation(DotEnter);
	}
	
	UFUNCTION(BlueprintOverride)
	void RemoveFromScreen()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if (bIsPrimaryTarget)
		{
			Circle.SetRenderOpacity(
				Math::FInterpConstantTo(
					Circle.RenderOpacity,
					1.0,
					InDeltaTime,
					5.0
				),
			);

			AnimTime += InDeltaTime * 10.0;

			UMaterialInstanceDynamic CircleMaterial = Circle.GetDynamicMaterial();
			CircleMaterial.SetScalarParameterValue(n"Time", AnimTime);

			if (!bPlayedReadyAnim)
			{
				PlayAnimation(Ready);
				bPlayedReadyAnim = true;
			}
		}
		else
		{
			Circle.SetRenderOpacity(
				Math::FInterpConstantTo(
					Circle.RenderOpacity,
					0.0,
					InDeltaTime,
					5.0
				),
			);

			if (bPlayedReadyAnim && IsAnimationPlaying(Ready))
				bPlayedReadyAnim = false;
		}

		if (bIsInDelayedRemove)
		{
			MainContainer.SetRenderOpacity(
				Math::FInterpConstantTo(
					MainContainer.RenderOpacity,
					0.0,
					InDeltaTime,
					4.0
				),
			);

			if (MainContainer.RenderOpacity < 0.001)
				FinishRemovingWidget();
		}
		else
		{
			MainContainer.SetRenderOpacity(
				Math::FInterpConstantTo(
					MainContainer.RenderOpacity,
					1.0,
					InDeltaTime,
					4.0
				),
			);
		}
	}
}