class USkylineBossTankDangerDecalCapability : USkylineBossTankChildCapability
{
	TPerPlayer<UDecalComponent> Decal;
	TPerPlayer<UMaterialInstanceDynamic> DecalMID;
	TPerPlayer<FHazeAcceleratedFloat> InViewAlpha;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		for (auto Player : Game::Players)
		{
			Decal[Player] = UDecalComponent::Create(Owner);
			Decal[Player].bAbsoluteLocation = true;
			Decal[Player].bAbsoluteRotation = true;
			DecalMID[Player] = Material::CreateDynamicMaterialInstance(Decal[Player], BossTank.DangerDecalMaterial);
			DecalMID[Player].SetScalarParameterValue(n"HazeToggle_VisibleForMio", (Player.IsMio() ? 1.0 : 0.0));
			DecalMID[Player].SetScalarParameterValue(n"HazeToggle_VisibleForZoe", (Player.IsZoe() ? 1.0 : 0.0));
			Decal[Player].DecalMaterial = DecalMID[Player];
			Decal[Player].SetHiddenInGame(true);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		for (auto Player : Game::Players)
			Decal[Player].DestroyComponent(Owner);
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
	void OnActivated()
	{
		for (auto Player : Game::Players)
		{
			Decal[Player].SetHiddenInGame(false);
			Decal[Player].SetWorldScale3D(FVector(4.0, 1.0, 1.0));
		}
	}	

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for (auto Player : Game::Players)
			Decal[Player].SetHiddenInGame(true);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		for (auto Player : Game::Players)
		{
//			Decal[Player].SetWorldScale3D(FVector(4.0, 2.0, 2.0));

			bool bInView = SceneView::IsInView(Player, BossTank.ActorLocation, FVector2D(-0.4, 1.4), FVector2D(-0.4, 1.4));
			InViewAlpha[Player].AccelerateTo((bInView ? 0.0 : 1.0), 0.5, DeltaTime);

			FVector TargetToBoss = Player.ActorLocation - BossTank.ActorLocation;			
			FVector BossViewDirection = (Player.ViewLocation - BossTank.ActorLocation).VectorPlaneProject(FVector::UpVector).SafeNormal;
			float BossViewDot = Player.ViewRotation.ForwardVector.VectorPlaneProject(FVector::UpVector).SafeNormal.DotProduct(BossViewDirection);
			float DistanceOpacity = 1.0 - Math::GetMappedRangeValueClamped(FVector2D(5000.0, 15000.0), FVector2D(0.0, 1.0), TargetToBoss.Size());

			DecalMID[Player].SetScalarParameterValue(n"Opacity", Math::Max(0.0, InViewAlpha[Player].Value * DistanceOpacity));
			FVector Location = FVector(Player.ActorLocation.X, Player.ActorLocation.Y, BossTank.ActorLocation.Z) -TargetToBoss.VectorPlaneProject(FVector::UpVector).SafeNormal * 300.0;
//			Debug::DrawDebugPoint(Location, 45.0, FLinearColor::Red, 0.0);
			Decal[Player].WorldLocation = Location;
			Decal[Player].WorldRotation = FRotator::MakeFromZX(-TargetToBoss.VectorPlaneProject(FVector::UpVector).SafeNormal, FVector::UpVector);
		}
	}
};