


// class UIslandNunchuckPickTargetCapability : UHazePlayerCapability
// {
// 	default CapabilityTags.Add(n"NunchuckPickTarget");

// 	//default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

// 	default TickGroup = EHazeTickGroup::BeforeMovement;

// 	UPlayerTargetablesComponent TargetContainer;
// 	UPlayerIslandNunchuckUserComponent MeleeComp;
// 	UPlayerAimingComponent AimingComp;
// 	//UPlayerMovementComponent MoveComp;
// 	//EPlayerScifiMeleeMoveType LastFramesMoveType = EPlayerScifiMeleeMoveType::MAX;
	
// 	UFUNCTION(BlueprintOverride)
// 	void Setup()
// 	{
// 		TargetContainer = UPlayerTargetablesComponent::Get(Player);
// 		MeleeComp = UPlayerIslandNunchuckUserComponent::Get(Owner);
// 		AimingComp = UPlayerAimingComponent::Get(Player);
// 		//MoveComp = UPlayerMovementComponent::Get(Owner);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	bool ShouldActivate() const
// 	{	
// 		// if(MeleeComp.IsInBlockedActionWindow())
// 		// 	return false;

// 		// if(!MeleeComp.HasWeaponEquiped())
// 		// 	return false;

// 		return true;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	bool ShouldDeactivate() const
// 	{
// 		// if(!MeleeComp.HasWeaponEquiped())
// 		// 	return true;
		
// 		return false;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated()
// 	{
// 		FAimingSettings PassiveAimSettings;
// 		PassiveAimSettings.bShowCrosshair = false;
// 		PassiveAimSettings.bApplyAimingSensitivity = false;
// 		PassiveAimSettings.bUseAutoAim = true;
// 		AimingComp.StartAiming(this, PassiveAimSettings);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated()
// 	{
// 		AimingComp.StopAiming(this);
// 		//MeleeComp.ActionEpiCenter.IsValid();
// 		//MeleeComp.TargetLocationData = FIslandNunchuckTargetLocationData();
// 		//MeleeComp.PotentialTargets.Empty();
// 		//MeleeComp.PrimaryTarget = nullptr;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void TickActive(float DeltaTime)
// 	{
// 		auto PrimeTarget = TargetContainer.GetPrimaryTarget(UIslandNunchuckTargetableComponent);
		
// 		//TArray<UTargetableComponent> Targetables;
// 		//TargetContainer.GetPossibleTargetables(UScifiMeleeTargetableComponent, Targetables);

// 		// //if(MeleeComp.bCanUpdateTargets)
// 		// {
// 		// 	MeleeComp.PotentialTargets.Empty();

// 		// 	// Add all the targets to the potential targets;
// 		// 	for(UTargetableComponent Targetable: Targetables)
// 		// 	{
// 		// 		UScifiMeleeTargetableComponent MeleeTargetable = Cast<UScifiMeleeTargetableComponent>(Targetable);
// 		// 		if(MeleeComp.ActionEpiCenter.IsValid())
// 		// 			MeleeTargetable.ApplyInRangeTime(DeltaTime);
				
// 		// 		MeleeComp.PotentialTargets.Add(MeleeTargetable);
// 		// 	}	
// 		// }

// 		// Update the epicenter
// 		// auto Prime = GetPrimaryTarget();
// 		// if(MeleeComp.ActionEpiCenter.IsValid())
// 		// {
// 		// 	const float MoveSpeed = MeleeComp.Settings.EpicenterMoveSpeed;
// 		// 	MeleeComp.ActionEpiCenter.CurrentLocation = Math::VInterpConstantTo(MeleeComp.ActionEpiCenter.CurrentLocation, Player.ActorLocation, DeltaTime, MoveSpeed);
// 		// 	if(Prime != nullptr)
// 		// 	{
// 		// 		MeleeComp.ActionEpiCenter.InvalidTime += DeltaTime;
// 		// 		if(MeleeComp.ActionEpiCenter.InvalidTime >= MeleeComp.GetKeepEpicenterTime(Prime.Owner.GetDistanceTo(Player)))
// 		// 		{
// 		// 			MeleeComp.ActionEpiCenter.Invalidate();
// 		// 		}
// 		// 	}
// 		// 	else if(!MeleeComp.Weapon.bIsVisible)
// 		// 	{
// 		// 		MeleeComp.ActionEpiCenter.Invalidate();
// 		// 	}
// 		// }
	
// 		// else if(MeleeComp.ActionEpiCenter.bIsValid && !MoveComp.MovementInput.IsNearlyZero())
// 		// {
// 		// 	const FVector PrevLocation = MeleeComp.ActionEpiCenter.CurrentLocation;
// 		// 	MeleeComp.ActionEpiCenter.CurrentLocation += MoveComp.MovementInput * DeltaTime * MeleeComp.EpicenterMovespeed;

// 		// 	// Make sure we dont move away to much
// 		// 	if(MeleeComp.MaxEpicenterMoveDistance >= 0 
// 		// 		&& MeleeComp.ActionEpiCenter.CurrentLocation.DistSquared(MeleeComp.ActionEpiCenter.CreationLocation) > Math::Square(MeleeComp.MaxEpicenterMoveDistance))
// 		// 	{
// 		// 		MeleeComp.ActionEpiCenter.CurrentLocation = PrevLocation;
// 		// 	}
// 		// }

// 		// // DEBUG
// 		// #if !RELEASE
		
// 		// if(MeleeComp.DebugDrawer.IsVisible())
// 		// {
// 		// 	if(MeleeComp.ActionEpiCenter.IsValid())
// 		// 	{
// 		// 		FVector CenterLocation = MeleeComp.ActionEpiCenter.CurrentLocation;

// 		// 		for(auto It : MeleeComp.Settings.EpiCenterRangeData)
// 		// 		{
// 		// 			Debug::DrawDebugCylinder(CenterLocation, CenterLocation + (MoveComp.WorldUp * 100), It.MaxTargetRange.GetFinalizedValue(MeleeComp.DefaultReachTargetRange), LineColor = FLinearColor::Red);
// 		// 		}

// 		// 		for(auto Target : MeleeComp.PotentialTargets)
// 		// 		{
// 		// 			if(Target == Prime)
// 		// 				Debug::DrawDebugDiamond(Target.WorldLocation + (FVector::UpVector * 100), 50.0, LineColor = FLinearColor::Red);
// 		// 			else
// 		// 				Debug::DrawDebugDiamond(Target.WorldLocation + (FVector::UpVector * 100), 50.0, LineColor = FLinearColor::White);
// 		// 		}
// 		// 	}
// 		// 	else
// 		// 	{
// 		// 		float TargetableRange = MeleeComp.DefaultReachTargetRange;
// 		// 		if(Prime != nullptr)
// 		// 			TargetableRange = MeleeComp.GetReachTargetRange(Prime);

// 		// 		Debug::DrawDebugCylinder(Player.ActorLocation, Player.ActorLocation + (MoveComp.WorldUp * 100), TargetableRange, LineColor = FLinearColor::Yellow);

// 		// 		for(auto Target : MeleeComp.PotentialTargets)
// 		// 		{
// 		// 			if(Target == Prime)
// 		// 				Debug::DrawDebugDiamond(Target.WorldLocation + (FVector::UpVector * 100), 50.0, LineColor = FLinearColor::Red);
// 		// 			else
// 		// 				Debug::DrawDebugDiamond(Target.WorldLocation + (FVector::UpVector * 100), 50.0, LineColor = FLinearColor::White);
// 		// 		}
// 		// 	}

// 		// }
// 		// #endif


// 		// // No active moves, update the current target
// 		// if(MeleeComp.CurrentMoveType == EPlayerScifiMeleeMoveType::MAX)
// 		// {
// 		// 	MeleeComp.PrimaryTarget = TargetContainer.GetPrimaryTarget(UScifiMeleeTargetableComponent);
// 		// 	MeleeComp.ActionEpiCenter = MeleeComp.PrimaryTarget.WorldLocation;
// 		// }
// 		// else if(MeleeComp.CurrentMoveType != LastFramesMoveType && MeleeComp.PrimaryTarget != nullptr)
// 		// {
// 		// 	MeleeComp.ActionEpiCenter = MeleeComp.PrimaryTarget.WorldLocation;
// 		// 	LastFramesMoveType = MeleeComp.CurrentMoveType;
// 		// }


// 		//MeleeComp.LastTargetDirection = FVector::ZeroVector;
// 		//if(MeleeComp.PrimaryTarget != nullptr)
// 		//Debug::DrawDebugSphere(MeleeComp.PrimaryTarget.WorldLocation);
// 		// MeleeComp.HasActiveMoveLocation = ActiveMoveTargets.Num() > 0;
// 		// if(MeleeComp.HasActiveMoveLocation)
// 		// {			
// 		// 	FVector TargetLocation;			
// 		// 	for(UTargetableComponent Targetable: ActiveMoveTargets)
// 		// 	{
// 		// 		TargetLocation += Targetable.WorldLocation;
// 		// 	}
// 		// 	MeleeComp.ActiveMoveLocation = TargetLocation / MeleeComp.CurrentTargets.Num();
// 		// }

// 		// TEMP, remove when we have real icons
// 		if(PrimeTarget != nullptr)
// 		{
// 			FVector WidgetLocation = PrimeTarget.WorldLocation + PrimeTarget.WidgetVisualOffset;
// 			FVector CameraLocation = Player.GetViewTransform().GetLocation();
			
// 			FQuat WidgetRotation = (CameraLocation - WidgetLocation).ToOrientationQuat();
// 			WidgetRotation = WidgetRotation * FRotator(0.0, Time::GameTimeSeconds * 100, 0.0).Quaternion();
			
// 			float Distance = CameraLocation.Distance(PrimeTarget.WorldLocation);
// 			float Radius = Math::Tan(Math::DegreesToRadians(45)) * Distance * 0.025;
// 			Debug::DrawDebugDiamond(WidgetLocation, Radius, WidgetRotation.Rotator(), LineColor = FLinearColor::DPink, bDrawInForeground = true);
// 		}
// 	}

// 	// UScifiMeleeTargetableComponent GetPrimaryTarget() const
// 	// {
// 	// 	if(MeleeComp.PrimaryTarget != nullptr && !MeleeComp.PrimaryTarget.IsDisabled())
// 	// 		return MeleeComp.PrimaryTarget;
// 	// 	else
// 	// 		return TargetContainer.GetPrimaryTarget(UScifiMeleeTargetableComponent);
// 	// }
// }