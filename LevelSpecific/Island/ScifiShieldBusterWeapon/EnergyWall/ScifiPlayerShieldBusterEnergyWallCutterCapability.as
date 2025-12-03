
class UScifiPlayerShieldBusterEnergyWallCutterCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"ShieldBuster");
	
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 110;

	default DebugCategory = n"ShieldBuster";

	UScifiPlayerShieldBusterManagerComponent Manager;
	//UScifiShieldBusterTargetableComponent AttachComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Manager = UScifiPlayerShieldBusterManagerComponent::Get(Player);
	}
	
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Manager.PendingWallImpacts.Num() > 0)
			return true;

		if(Manager.ActiveWallCutters.Num() > 0)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Manager.PendingWallImpacts.Num() > 0)
			return false;

		if(Manager.ActiveWallCutters.Num() > 0)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Apply all new impacts
		for(auto NewImpact : Manager.PendingWallImpacts)
		{
			ApplyNewImpact(NewImpact);
		}
		Manager.PendingWallImpacts.Reset();

		// Update all current impacts
		for(int i = Manager.ActiveWallCutters.Num() - 1; i >= 0; --i)
		{
			auto Cutter = Manager.ActiveWallCutters[i];
			float ActiveTime = Time::GetGameTimeSince(Cutter.LastImpactTime);
			if(ActiveTime <= KINDA_SMALL_NUMBER)
				continue;

			auto CutterSettings = Cutter.CurrentAttachedWall.CutterSettings;
			float DegenSpeed = CutterSettings.DegenerationSpeed;
			DegenSpeed *= CutterSettings.DegenerationSpeedMultiplier.GetFloatValue(ActiveTime);

			Cutter.CurrentAttachedWall.WallMesh.SetScalarParameterValueOnMaterials(n"Bubble0Radius", Cutter.CurrentSize);
			Cutter.CurrentAttachedWall.WallMesh.SetVectorParameterValueOnMaterials(n"Bubble0Loc", Cutter.ActorLocation);

			Cutter.CurrentSize = Math::FInterpConstantTo(Cutter.CurrentSize, 0.0, DeltaTime, DegenSpeed);
			if(Cutter.CurrentSize <= KINDA_SMALL_NUMBER)
			{
				if(Cutter.CurrentAttachedWall != nullptr)
				{
					Cutter.CurrentAttachedWall.CurrentWallCutter = nullptr;
					Cutter.CurrentAttachedWallTargetComponent = nullptr;
					Cutter.CurrentAttachedWall = nullptr;
					Cutter.DetachRootComponentFromParent();
				}
				
				Manager.DeactiveWallCutter(Cutter);
				Manager.ActiveWallCutters.RemoveAtSwap(i);
			}
		}
	}

	void ApplyNewImpact(FScifiShieldBusterPendingWallImpactData NewImpact)
	{
		auto Cutter = NewImpact.WallCutter;
		auto Wall = Cast<AScifiShieldBusterEnergyWall>(NewImpact.Impact.Actor);
		auto WallTarget = Cast<UScifiShieldBusterEnergyWallTargetableComponent>(NewImpact.Impact.Target);
		if(Cutter.CurrentAttachedWall == nullptr)
		{
			Wall.CurrentWallCutter = Cutter;
			Cutter.CurrentAttachedWall = Wall;
			Cutter.CurrentAttachedWallTargetComponent = WallTarget;
			//AttachComp = WallTarget;
				
			Cutter.AttachToComponent(WallTarget);
			Manager.ActivateWallCutter(Cutter);
			Manager.ActiveWallCutters.Add(Cutter);
		}
		else
		{
			check(Wall.CurrentWallCutter == Cutter);	
		}

		Cutter.LastImpactTime = Time::GetGameTimeSeconds();
		auto WallSettings = Wall.CutterSettings;

		float MinSize = Math::Max(WallSettings.ImpactSizeGenerationAmount, WallSettings.ImpactMinSize);
		if(Cutter.CurrentSize < MinSize)
			Cutter.CurrentSize = Math::Min(MinSize, WallSettings.MaxSize);
		else
			Cutter.CurrentSize = Math::Min(Cutter.CurrentSize + WallSettings.ImpactSizeGenerationAmount, WallSettings.MaxSize);

		Wall.WallMesh.SetScalarParameterValueOnMaterials(n"Bubble0Radius", Cutter.CurrentSize);
		Wall.WallMesh.SetVectorParameterValueOnMaterials(n"Bubble0Loc", WallTarget.GetWorldLocation());

		// Broadcast to the generic impact respons component
		Wall.ImpactResponse.OnApplyImpact(Player, WallTarget);

		// Trigger impact event
		FScifiPlayerShieldBusterOnImpactEventData ImpactData;
		ImpactData.ImpactLocation = NewImpact.Impact.ImpactLocation;
		ImpactData.ImpactTarget = NewImpact.Impact.Target;
		UScifiPlayerShieldBusterEventHandler::Trigger_OnImpact(Player, ImpactData);
	}
};