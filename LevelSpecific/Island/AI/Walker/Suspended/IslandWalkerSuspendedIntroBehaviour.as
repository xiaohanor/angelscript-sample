class UIslandWalkerSuspendedIntroBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);

	UIslandWalkerSettings Settings;
	UIslandWalkerComponent WalkerComp;
	UIslandWalkerNeckRoot NeckRoot;
	TArray<UIslandWalkerCablesTargetRoot> CablesTargetRoots;
	UIslandWalkerLegsComponent LegsComp;
	UIslandWalkerAnimationComponent WalkerAnimComp;
	float HoistDuration = 1.0;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandWalkerSettings::GetSettings(Owner);
		WalkerComp = UIslandWalkerComponent::GetOrCreate(Owner);
		NeckRoot = UIslandWalkerNeckRoot::Get(Owner);
		Owner.GetComponentsByClass(CablesTargetRoots);
		LegsComp = UIslandWalkerLegsComponent::Get(Owner);
		WalkerAnimComp = UIslandWalkerAnimationComponent::Get(Owner);
		UIslandWalkerPhaseComponent::Get(Owner).OnSkipIntro.AddUFunction(this, n"OnSkipIntro");
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if(WalkerComp.bSuspended)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > HoistDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		NeckRoot.Head.PowerDown();
		UMovementGravitySettings::SetGravityScale(Owner, 0.0, IslandWalker::SuspendedInstigator, EHazeSettingsPriority::Gameplay);
		AnimComp.RequestFeature(FeatureTagWalker::Suspended, SubTagWalkerSuspended::Idle, EBasicBehaviourPriority::Medium, this);

		// Power up cables targets so they can be launched during cutscene.
		for (UIslandWalkerCablesTargetRoot CablesRoot : CablesTargetRoots)
		{
			CablesRoot.Target.PowerUp();
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		AnimComp.ClearFeature(this);	
		WalkerAnimComp.HeadAnim.ClearFeature(this);	
		CompleteIntro();
	}

	void CompleteIntro()
	{
		WalkerComp.bSuspended = true;
		WalkerComp.SuspendIntroCompleteTime = Time::GameTimeSeconds;

		// Power up any remaining cables targets
		for (UIslandWalkerCablesTargetRoot CablesRoot : CablesTargetRoots)
		{
			CablesRoot.Target.PowerUp();
		}
		
		NeckRoot.Head.PowerUp();
		NeckRoot.DeployHead();
		LegsComp.PowerDownLegs();
	}

	bool AreAllCablesLatchedOn()
	{
		if (WalkerComp.DeployedCables.Num() == 0)
			return false;

		for (AIslandWalkerSuspensionCable Cable : WalkerComp.DeployedCables)
		{
			if (!Cable.IsLatchedOn())
				return false;
		}
		return true;
	}

	void DeployCables()
	{
		TListedActors<AIslandWalkerSuspensionCable> Cables;
		if (Cables.Num() == 0)
			return; // No cables to deploy!

		// Couplings are attached to cable targets
		AAIIslandWalker Walker = Cast<AAIIslandWalker>(Owner);

		// Clockwise sort couplings
		TArray<UIslandWalkerSuspendCouplingComponent> SortedCouplings;
		SortedCouplings.Add(Walker.FrontCablesTargetRoot.Target.CableCouplingRight);
		SortedCouplings.Add(Walker.RearCablesTargetRoot.Target.CableCouplingRight);
		SortedCouplings.Add(Walker.RearCablesTargetRoot.Target.CableCouplingLeft);
		SortedCouplings.Add(Walker.FrontCablesTargetRoot.Target.CableCouplingLeft);

		// Sort cables in clockwise order around their center location starting with 
		// the first one to the right in front of walker direction
		TArray<AIslandWalkerSuspensionCable> SortedCables;
		TArray<float> CableYaws;
		FVector CableLocSum = FVector::ZeroVector;
		for (AIslandWalkerSuspensionCable Cable : Cables)
		{
			CableLocSum += Cable.CableEndRoot.WorldLocation;
		}
		FVector CableCenter = CableLocSum / Cables.Num();
		for (AIslandWalkerSuspensionCable Cable : Cables)
		{
			float Yaw = FRotator::ClampAxis((Cable.CableEndRoot.WorldLocation - CableCenter).Rotation().Yaw - Owner.ActorRotation.Yaw);
			int iSlot = 0;
			for (; iSlot < SortedCables.Num(); iSlot++)
			{
				if (Yaw < CableYaws[iSlot])
						break;
			}
			SortedCables.Insert(Cable, iSlot);
			CableYaws.Insert(Yaw, iSlot);
		}

		for (int i = 0; i < Math::Min(SortedCouplings.Num(), SortedCables.Num()); i++)
		{
			SortedCables[i].Deploy(Owner, SortedCouplings[i], Settings.SuspendCableDeployDuration + Math::RandRange(-0.5, 0.5));		
			WalkerComp.DeployedCables.AddUnique(SortedCables[i]);	
		}
	}

	UFUNCTION()
	private void OnSkipIntro(EIslandWalkerPhase NewPhase)
	{
		if (NewPhase != EIslandWalkerPhase::Suspended)
			return;

		for (AIslandWalkerLegTarget Leg : LegsComp.LegTargets)
		{
			Leg.RemoveLeg();
		}
		
		DeployCables();		
		for (AIslandWalkerSuspensionCable Cable : WalkerComp.DeployedCables)
		{
			Cable.bWasLatchedOn = true;
			Cable.LatchOnFraction = 1.0;
			Cable.Update(100.0);
		}
		CompleteIntro();		
	}
}