class AMeltdownSplitSlideWhiteSpaceRift : AWorldLinkDoubleActor
{
	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	UBillboardComponent BillboardComp;

	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	UHazeSkeletalMeshComponentBase ScifiMeshComp;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	UHazeSkeletalMeshComponentBase FantasyMeshComp;

	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	USceneComponent ScifiBridgeRootComp;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	USceneComponent FantasyBridgeRootComp;

	UPROPERTY(EditInstanceOnly)
	TArray<AActor> ActorsToHide;
	TArray<UStaticMeshComponent> MeshComps;

	UPROPERTY(EditInstanceOnly)
	TArray<AMeltdownBossCubeGrid> MeltdownCubesToUnhide;

	UPROPERTY(EditInstanceOnly)
	TArray<AActor> ActorsToNotKeepRendered;

	UPROPERTY()
	FHazeTimeLike SphereGrowTimeLike;
	default SphereGrowTimeLike.Duration = 4.0;
	default SphereGrowTimeLike.UseSmoothCurveZeroToOne();

	UPROPERTY()
	FHazeTimeLike BridgeShakeTimeLike;
	default BridgeShakeTimeLike.Duration = 0.6;
	default BridgeShakeTimeLike.UseSmoothCurveZeroToOne();

	UPROPERTY()
	UMaterialInstance MI;
	UMaterialInstanceDynamic MID1;
	UMaterialInstanceDynamic MID2;

	FPostProcessSettings PPSettingsMio;
	FPostProcessSettings PPSettingsZoe;

	UPROPERTY()
	float MinRadius = 0.0;

	UPROPERTY()
	float MaxRadius = 20000.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		SphereGrowTimeLike.BindUpdate(this, n"SphereGrowTimeLikeUpdate");
		BridgeShakeTimeLike.BindUpdate(this, n"BridgeShakeTimeLikeUpdate");
		MID1 = Material::CreateDynamicMaterialInstance(this, MI);
		MID2 = Material::CreateDynamicMaterialInstance(this, MI);

		FWeightedBlendables WeightedBlendables1;
		FWeightedBlendables WeightedBlendables2;

		FWeightedBlendable WeightedBlendable1;
		FWeightedBlendable WeightedBlendable2;

		WeightedBlendable1.Object = MID1;
		WeightedBlendable1.Weight = 1.0;

		WeightedBlendable2.Object = MID2;
		WeightedBlendable2.Weight = 1.0;

		WeightedBlendables1.Array.Add(WeightedBlendable1);
		WeightedBlendables2.Array.Add(WeightedBlendable2);

		PPSettingsMio.WeightedBlendables = WeightedBlendables1;
		PPSettingsZoe.WeightedBlendables = WeightedBlendables2;

		Game::Mio.AddCustomPostProcessSettings(PPSettingsMio, 1.0, this);
		Game::Zoe.AddCustomPostProcessSettings(PPSettingsZoe, 1.0, this);

		MID1.SetScalarParameterValue(n"whitespaceData_Tiling", 0.075);
		MID1.SetScalarParameterValue(n"whitespaceData_BorderWidth", 2000.0);
		MID1.SetVectorParameterValue(n"whitespaceData_Center", FLinearColor(ActorLocation));

		MID2.SetScalarParameterValue(n"whitespaceData_Tiling", 0.075);
		MID2.SetScalarParameterValue(n"whitespaceData_BorderWidth", 2000.0);
		MID2.SetVectorParameterValue(n"whitespaceData_Center", FLinearColor(ActorLocation - FVector::ForwardVector * 500000.0));
		
		SetActorHiddenInGame(true);

		for (auto ActorToNotKeepRendered : ActorsToNotKeepRendered)
		{
			TArray<UActorComponent> ActorComps;
			ActorToNotKeepRendered.GetAllComponents(UStaticMeshComponent, ActorComps);
			
			for (auto ActorComp : ActorComps)
			{
				auto MeshComp = Cast<UStaticMeshComponent>(ActorComp);
				if (MeshComp != nullptr)
				{
					MeshComps.AddUnique(MeshComp);
				}
			}
		}
	}

	// UFUNCTION()
	// private void RaderAppearTimeLikeUpdate(float CurrentValue)
	// {
	// 	FVector Location = FVector::UpVector * Math::Lerp(-26000.0, -10000.0, CurrentValue);

	// 	ScifiMeshComp.SetRelativeLocation(Location);
	// 	FantasyMeshComp.SetRelativeLocation(Location);
	// }

	UFUNCTION()
	void Activate()
	{
		SphereGrowTimeLike.Play();

		Game::Mio.Mesh.SetCustomDepthStencilValue(16);
		Game::Mio.Mesh.SetRenderCustomDepth(true);
		Game::Mio.Mesh.MarkRenderStateDirty();

		Game::Zoe.Mesh.SetCustomDepthStencilValue(16);
		Game::Zoe.Mesh.SetRenderCustomDepth(true);
		Game::Zoe.Mesh.MarkRenderStateDirty();

		auto Manager = ASplitTraversalManager::GetSplitTraversalManager();

		for (auto Player : Game::Players)
		{
			auto Mesh = Manager.PlayerCopies[Player].Mesh;
			auto ShieldMesh = UStaticMeshComponent::Get(Manager.PlayerCopies[Player].DuplicatedHoverboard);

			Mesh.SetCustomDepthStencilValue(16);
			Mesh.SetRenderCustomDepth(true);
			Mesh.MarkRenderStateDirty();

			ShieldMesh.SetCustomDepthStencilValue(16);
			ShieldMesh.SetRenderCustomDepth(true);
			ShieldMesh.MarkRenderStateDirty();
		}

		for (auto StaticMesh : MeshComps)
		{
			StaticMesh.SetCustomDepthStencilValue(16);
			StaticMesh.SetRenderCustomDepth(true);
			StaticMesh.MarkRenderStateDirty();
		}

		// ScifiMeshComp.SetCustomDepthStencilValue(16);
		// ScifiMeshComp.SetRenderCustomDepth(true);
		// ScifiMeshComp.MarkRenderStateDirty();

		// FantasyMeshComp.SetCustomDepthStencilValue(16);
		// FantasyMeshComp.SetRenderCustomDepth(true);

		BP_Activate();
	}

	UFUNCTION()
	protected void RenderMeshHack(UStaticMeshComponent MeshComp)
	{
		MeshComp.SetCustomDepthStencilValue(16);
		MeshComp.SetRenderCustomDepth(true);
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Activate(){}

	UFUNCTION()
	private void SphereGrowTimeLikeUpdate(float CurrentValue)
	{
		MID1.SetScalarParameterValue(n"whitespaceData_Radius", Math::Lerp(-MinRadius, -MaxRadius, CurrentValue));
		MID2.SetScalarParameterValue(n"whitespaceData_Radius", Math::Lerp(-MinRadius, -MaxRadius, CurrentValue));

		float Brightness = Math::Lerp(1.0, 150.0, CurrentValue);

		PPSettingsMio.bOverride_AutoExposureMaxBrightness = true;
		PPSettingsMio.bOverride_AutoExposureMinBrightness = true;
		PPSettingsMio.AutoExposureMaxBrightness = Brightness;
		PPSettingsMio.AutoExposureMinBrightness = Brightness;
	}

	UFUNCTION()
	protected void ShakeBridge()
	{
		BridgeShakeTimeLike.PlayFromStart();
	}

	UFUNCTION()
	protected void SwitchBridge()
	{
		for (auto ActorToHide : ActorsToHide)
		{
			ActorToHide.SetActorHiddenInGame(true);
			
			TArray<AActor> AttachedActors;
			ActorToHide.GetAttachedActors(AttachedActors);
			for (auto AttachedActor : AttachedActors)
				AttachedActor.SetActorHiddenInGame(true);
		}

		for (auto MeltdownCubeToUnhide : MeltdownCubesToUnhide)
		{
			MeltdownCubeToUnhide.SetActorHiddenInGame(false);

			auto InstancedMesh = MeltdownCubeToUnhide.InstancedMesh;

			InstancedMesh.SetCustomDepthStencilValue(16);
			InstancedMesh.SetRenderCustomDepth(true);
			InstancedMesh.MarkRenderStateDirty();
		}
	}

	UFUNCTION()
	private void BridgeShakeTimeLikeUpdate(float CurrentValue)
	{
		FRotator Rotation = FRotator(0.0, 0.0, Math::Lerp(0.0, 5.0, CurrentValue));
		ScifiBridgeRootComp.SetRelativeRotation(Rotation);
		FantasyBridgeRootComp.SetRelativeRotation(Rotation);
	}

	UFUNCTION()
	void GlitchVFXOnHoverboards()
	{
		for (auto Player : Game::Players)
		{
			SpawnGlitchEffect(Player.ActorLocation);
			SpawnGlitchEffect(Player.ActorLocation - FVector::ForwardVector * 500000.0);
		}
	}

	UFUNCTION(BlueprintEvent)
	private void SpawnGlitchEffect(FVector WorldLocation){}
};