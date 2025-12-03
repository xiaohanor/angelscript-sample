UCLASS(HideCategories = "Rendering ComponentTick Advanced Disable Debug Activation Cooking LOD Collision")
class UIslandWalkerLegRoot : USceneComponent
{
	UPROPERTY(EditAnywhere)
	TSubclassOf<AIslandWalkerLegTarget> LegClass;

	UPROPERTY()
	EIslandForceFieldType ForceFieldType = EIslandForceFieldType::Blue;

	UPROPERTY(VisibleAnywhere, NotEditable)
	FName ForceFieldAttachSocket = n"RightFrontMiddleLeg3";

	FName BluePanelSocket = NAME_None;
	FName RedPanelSocket = NAME_None;
	FName CoverPanelSocket = NAME_None;
	EWalkerHatch HatchAnimType;

	UIslandWalkerSettings Settings;
	UHazeSkeletalMeshComponentBase Mesh;
	AIslandOverloadShootablePanel CoverPanel;
	AIslandWalkerLegTarget LegTarget;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AHazeCharacter Walker = Cast<AHazeCharacter>(Owner);
		Mesh = Walker.Mesh;
		Settings = UIslandWalkerSettings::GetSettings(Walker);
	}

	void SetupTarget(UIslandWalkerLegsComponent LegsComp)
	{
		if (!LegClass.IsValid())
			return; 
		
		LegTarget = SpawnActor(LegClass, bDeferredSpawn = true, Level = Owner.Level);
		LegTarget.MakeNetworked(this, n"LegTarget");
		LegTarget.OwnerWalker = Cast<AHazeActor>(Owner);
		LegTarget.ForceFieldComp.Walker = LegTarget.OwnerWalker;
		LegTarget.ForceFieldComp.Type = ForceFieldType;
		LegTarget.RedPanelSocket = RedPanelSocket;
		LegTarget.BluePanelSocket = BluePanelSocket;
		LegTarget.HatchAnimType = HatchAnimType;
		LegTarget.LegBone = BaseBone;
		LegTarget.ForceFieldComp.AttachToComponent(Mesh, ForceFieldAttachSocket, EAttachmentRule::SnapToTarget);
		LegsComp.AddLeg(LegTarget);
		FinishSpawningActor(LegTarget);

		LegTarget.AttachToComponent(this, NAME_None, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		LegTarget.OnLegDestroyed.AddUFunction(this, n"OnLegDestroyed");
		LegTarget.OnLegRespawned.AddUFunction(this, n"OnLegRespawned");

		// Cover panel opens the cover which protects leg.
		CoverPanel = SpawnActor(LegTarget.PanelClass, bDeferredSpawn = true, Level = Owner.Level); 
		CoverPanel.UsableByPlayer = (ForceFieldType == EIslandForceFieldType::Blue) ? EHazePlayer::Mio : EHazePlayer::Zoe;
		CoverPanel.MakeNetworked(this, n"CoverPanel");
		FinishSpawningActor(CoverPanel);
		CoverPanel.AttachRootComponentTo(Mesh, CoverPanelSocket, EAttachLocation::SnapToTarget);
		CoverPanel.OnImpact.AddUFunction(this, n"OnCoverPanelImpact");
		CoverPanel.OnOvercharged.AddUFunction(this, n"OnCoverPanelOvercharged");
		CoverPanel.OnReset.AddUFunction(this, n"OnCoverPanelRecover");
		CoverPanel.OverchargeComp.bUseDataAssetSettings = false;
		CoverPanel.OverchargeComp.Settings_Property = Settings.CoverPanelOverchargeSettings;
		CoverPanel.OverchargeComp.Settings_Property.OverchargeColor = (ForceFieldType == EIslandForceFieldType::Blue) ? EIslandRedBlueOverchargeColor::Red : EIslandRedBlueOverchargeColor::Blue;
		CoverPanel.ActorScale3D = FVector::OneVector * 0.6;	
		LegTarget.CoverPanel = CoverPanel;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (LegTarget == nullptr)
			return;
		//Debug::DrawDebugSphere(LegTarget.CoverPivot.WorldLocation, 40);
	}

	UFUNCTION()
	private void OnLegDestroyed()
	{
		// Hide leg
		Mesh.HideBoneByName(BaseBone, EPhysBodyOp::PBO_None);

		// Hide attached components
		TArray<UPrimitiveComponent> AttachChildren;
		GetChildrenComponentsByClass(UPrimitiveComponent, true, AttachChildren);
		for (UPrimitiveComponent Child : AttachChildren)
		{
			if (Child.Owner != Owner)
				continue;
			Child.AddComponentVisualsBlocker(this);
			Child.AddComponentCollisionBlocker(this);
		}

		// Hide collision atached lower down on the leg
		FName OurBone = BaseBone;
		for (UPrimitiveComponent Comp : Owner.GetComponentsByTag(UPrimitiveComponent, n"LegCollision"))
		{
			FName Attach = Comp.AttachSocketName;
			for (int i = 0; i < 3; i++)
			{
				if (Attach.IsEqual(OurBone))
				{
					// This is on our leg
					Comp.AddComponentVisualsBlocker(this);
					Comp.AddComponentCollisionBlocker(this);
					break;	
				}
				Attach = Mesh.GetParentBone(Attach);
			}
		}
	}

	FName GetBaseBone() property
	{
		return Mesh.GetSocketBoneName(AttachSocketName);
	}

	UFUNCTION()
	private void OnLegRespawned()
	{
		// Show leg
		RemoveComponentVisualsBlocker(this);
		Mesh.UnHideBoneByName(BaseBone);

		// Show attached components
		TArray<UPrimitiveComponent> AttachChildren;
		GetChildrenComponentsByClass(UPrimitiveComponent, true, AttachChildren);
		for (UPrimitiveComponent Child : AttachChildren)
		{
			if (Child.Owner != Owner)
				continue;
			Child.RemoveComponentVisualsBlocker(this);
			Child.RemoveComponentCollisionBlocker(this);
		}
		// Enable collision attached lower down on the leg
		FName OurBone = BaseBone;
		for (UPrimitiveComponent Comp : Owner.GetComponentsByTag(UPrimitiveComponent, n"LegCollision"))
		{
			FName Attach = Comp.AttachSocketName;
			for (int i = 0; i < 3; i++)
			{
				if (Attach.IsEqual(OurBone))
				{
					// This is on our leg
					Comp.AddComponentVisualsBlocker(this);
					Comp.AddComponentCollisionBlocker(this);
					break;	
				}
				Attach = Mesh.GetParentBone(Attach);
			}
		}

	}

	UFUNCTION()
	private void OnCoverPanelRecover()
	{
		LegTarget.CloseCover();
	}

	UFUNCTION()
	private void OnCoverPanelOvercharged()
	{
		LegTarget.OpenCover();
	}

	UFUNCTION()
	private void OnCoverPanelImpact()
	{
	}
};

