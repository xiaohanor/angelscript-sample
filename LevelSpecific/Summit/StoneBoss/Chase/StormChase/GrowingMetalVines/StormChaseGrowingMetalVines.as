event void FOnStormChaseMetalVineMelted(AStormChaseGrowingMetalVines Vine);

class AStormChaseGrowingMetalVines : AHazeActor
{
	UPROPERTY()
	FOnStormChaseMetalVineMelted OnStormChaseMetalVineMelted;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent HitBox;
	default HitBox.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	default HitBox.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default HitBox.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Block);
	default HitBox.SetCollisionResponseToChannel(ECollisionChannel::WeaponTracePlayer, ECollisionResponse::ECR_Block);
	// default HitBox.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	// default HitBox.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	// default HitBox.SetCollisionResponseToChannel(ECollisionChannel::WeaponTracePlayer, ECollisionResponse::ECR_Block);
	// default HitBox.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent)
	UAcidResponseComponent AcidResponseComp;
	default AcidResponseComp.Shape.BoxExtents = HitBox.BoxExtent;

	UPROPERTY(DefaultComponent, Attach = Root)
	UAdultDragonAcidAutoAimComponent AutoAimComp;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AAcidDissolveSphere> DissolveSphereClass;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem VFXAsset;

	TArray<AAcidDissolveSphere> DissolveSpheres;
	TArray<UStaticMeshComponent> MeshComps;

	/* Ideally we want the niagara component attached to the mesh.
		Since the meshes are added on the BP layer so will the niagara components. */
	TArray<UNiagaraComponent> NiagaraComps;

	bool bIsGrowing = false;

	UPROPERTY(EditAnywhere)
	bool bStartFullyGrown = false;

	float GrowthSphereMaskRadius;

	UPROPERTY(EditAnywhere)
	float GrowthSpeed = 20000;

	UPROPERTY(EditAnywhere)
	float DissolveSpeed = 3000;

	UPROPERTY(EditAnywhere)
	float AcceleratedDissolve_TargetRadius = 4000;

	// How long it will take until we reach the acceelerated target radius
	UPROPERTY(EditAnywhere)
	float AcceleratedDissolve_Time = 0.4;

	UPROPERTY(EditInstanceOnly)
	ASerpentEventActivator SerpentEventActivator;

	bool bHasBeenActivated;

	FLinearColor AcidColor;

	UPROPERTY(EditAnywhere)
	FLinearColor GrowColor;

	float Bounds;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (!bStartFullyGrown && SerpentEventActivator != nullptr)
		{
			SerpentEventActivator.OnSerpentEventTriggered.AddUFunction(this, n"StartGrowing");
		}

		AcidColor = Cast<UMaterialInstanceConstant>(MeshComp.GetMaterial(0)).GetVectorParameterValue(n"AcidColor");

		AcidResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");
		FVector Origin, Extent;
		GetActorBounds(false, Origin, Extent, true);
		Bounds = Extent.Size();
		GrowthSphereMaskRadius = Bounds * 1.2;

		if (bStartFullyGrown)
		{
			GrowthSphereMaskRadius = 0;
			HitBox.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
			MeshComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
		}

		GetComponentsByClass(UStaticMeshComponent, MeshComps);
		for (auto MeshComponents : MeshComps)
		{
			if (!bStartFullyGrown)
			{
				MeshComponents.SetColorParameterValueOnMaterials(n"AcidColor", GrowColor);
			}
			MeshComponents.SetVectorParameterValueOnMaterials(
				FName(f"Dissolve_MeltingPoint"),
				ActorCenterLocation);
			MeshComponents.SetScalarParameterValueOnMaterials(FName(f"Dissolve_Radius"), GrowthSphereMaskRadius);
		}

		// get the niagara comps. The idea atm is to have one per mesh.
		GetComponentsByClass(UNiagaraComponent, NiagaraComps);
	}

	float TimeStampLastAcidHit = -1.0;

	FAcidHit ComplexTraceAcidHit(FAcidHit AcidHit)
	{
		FAcidHit NewAcidHit = AcidHit;

		FHitResult Hit;
		bool bHit = FindClosestPointOnComplexMesh(AcidHit.HitComponent, AcidHit.ImpactLocation, Hit);
		if (bHit)
		{
			NewAcidHit = AcidHit;
			NewAcidHit.HitComponent = Hit.Component;
			NewAcidHit.ImpactLocation = Hit.ImpactPoint;
			NewAcidHit.ImpactNormal = Hit.ImpactNormal;
		}

		return NewAcidHit;
	}

	bool FindClosestPointOnComplexMesh(UPrimitiveComponent Prim, FVector QueryPoint, FHitResult& OutHit)
	{
		int TraceAttempts = 1;
		if (Prim == nullptr || TraceAttempts <= 0)
			return false;

		for (int j = 0; j < TraceAttempts; ++j)
		{
			// FVector Offset = Math::GetRandomPointInSphere() * Prim.BoundsRadius * 2.0;
			FVector Offset = QueryPoint - Game::GetMio().ActorCenterLocation;

			FName BoneName;
			FVector ImpactPoint, ImpactNormal;
			FHitResult HitResult;

			// Prim.LineTraceComponent(
			// 	QueryPoint + Offset,
			// 	QueryPoint - Offset,
			// 	true,
			// 	true,
			// 	false,
			// 	ImpactPoint,
			// 	ImpactNormal,
			// 	BoneName,
			// 	HitResult
			// );

			bool bHit = Prim.SphereTraceComponent(
				QueryPoint - Offset,
				QueryPoint + Offset,
				// Offset.Size(),
				AdultAcidDragon::AcidProjectileRadius,
				true,
				false,
				false,
				ImpactPoint,
				ImpactNormal,
				BoneName,
				HitResult);

			// if(HitResult.bBlockingHit)
			if (bHit)
			{
				HitResult.SetbBlockingHit(true);
				OutHit = HitResult;
				return true;
			}

			// if(HitResult.bBlockingHit)
			// {
			// 	OutPoint = HitResult.ImpactPoint;
			// 	return true;
			// }

			// if (HitResult.Time > KINDA_SMALL_NUMBER && HitResult.Time < 1.0 - KINDA_SMALL_NUMBER)
			// {
			// 	// OutPoint = WorldTransform.InverseTransformPositionNoScale(HitResult.ImpactPoint);
			// 	OutPoint = HitResult.ImpactPoint;
			// 	return true;
			// }
		}

		return false;
	}

	int HitsRemaining = 8;

	UFUNCTION()
	private void OnAcidHit(FAcidHit AcidHit)
	{
		// Shader based cap atm.
		if (DissolveSpheres.Num() >= 8)
			return;

		if (HitsRemaining <= 0)
			return;

		// don't spawn sphere every frame if we are spraying
		const float TimeSinceLastHit = Time::GetGameTimeSince(TimeStampLastAcidHit);
		if (TimeSinceLastHit < 0.15)
			return;

		--HitsRemaining;

		FAcidHit Hit = ComplexTraceAcidHit(AcidHit);

		// Debug::DrawDebugPoint(Hit.ImpactLocation, 20.0, FLinearColor::Yellow, 3.0);

		TimeStampLastAcidHit = Time::GetGameTimeSeconds();

		auto DissolveSphere = SpawnActor(DissolveSphereClass, Hit.ImpactLocation);

		DissolveSphere.ActorToMaskCollision = this;
		DissolveSphere.CurrentGrowthSpeed = DissolveSpeed;

		const float AcidHitRadius = AdultAcidDragon::AcidProjectileRadius;

		// DissolveSphere.DissolveRadius = InitialDissolveRadius;
		DissolveSphere.SetAcceleratedDissolveRadiusTarget(
			AcceleratedDissolve_TargetRadius,
			AcidHitRadius,
			AcceleratedDissolve_Time);

		DissolveSpheres.Add(DissolveSphere);
		OnStormChaseMetalVineMelted.Broadcast(this);

		for (auto MeshComponents : MeshComps)
		{
			if (!bStartFullyGrown)
			{
				MeshComponents.SetColorParameterValueOnMaterials(n"AcidColor", AcidColor);
			}

			// MeshComponents.SetVectorParameterValueOnMaterials(
			// 	FName(f"Bubble0Loc"),
			// 	Hit.ImpactLocation);

			// MeshComponents.SetScalarParameterValueOnMaterials(FName(f"Bubble0Radius"), GrowthSphereMaskRadius);
			// MeshComponents.SetScalarParameterValueOnMaterials(FName(f"Bubble0Radius"), AcidHitRadius);

			// DissolveSphere.AddNiagaraComp(VFXAsset, MeshComponents, Hit.ImpactLocation, GrowthSphereMaskRadius);
			DissolveSphere.AddNiagaraComp(VFXAsset, MeshComponents, Hit.ImpactLocation, AcidHitRadius);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (DissolveSpheres.Num() > 0)
		{
			if ((DissolveSpheres[0].SphereComp.SphereRadius * 0.5) > Bounds)
			{
				AddActorDisable(this);
			}

			for (int i = DissolveSpheres.Num() - 1; i >= 0; i--)
			{
				if (DissolveSpheres[i] == nullptr || DissolveSpheres[i].IsActorBeingDestroyed())
				{
					DissolveSpheres.RemoveAt(i);
				}
			}

			for (int i = 0; i < DissolveSpheres.Num(); i++)
			{
				float Radius = DissolveSpheres[i].SphereComp.SphereRadius;
				for (auto MeshComponent : MeshComps)
				{
					MeshComponent.SetVectorParameterValueOnMaterials(
						FName(f"Bubble{i}Loc"),
						DissolveSpheres[i].ActorCenterLocation);
					MeshComponent.SetScalarParameterValueOnMaterials(FName(f"Bubble{i}Radius"), Radius);
				}

				DissolveSpheres[i].UpdateNiagara(DissolveSpheres);
			}

			// TODO (DB): Clean this up once we've settled on which params will be used
			if (DissolveSpheres.Num() > 0)
			{
				auto DissolveSphere = DissolveSpheres[0];

				for (auto MeshComponent : MeshComps)
				{
					MeshComponent.SetVectorParameterValueOnMaterials(
						FName(f"Dissolve_MeltingPoint"),
						DissolveSphere.ActorCenterLocation);
					MeshComponent.SetScalarParameterValueOnMaterials(FName(f"Dissolve_Radius"), DissolveSphere.SphereComp.SphereRadius);
				}
			}
		}
		else if (bIsGrowing)
		{
			GrowthSphereMaskRadius -= GrowthSpeed * DeltaSeconds;
			GrowthSphereMaskRadius = Math::Max(GrowthSphereMaskRadius, 0);
			// shrink a sphere so the vines grow from outside inwards

			for (auto MeshComponents : MeshComps)
			{
				MeshComponents.SetVectorParameterValueOnMaterials(
					FName(f"Bubble0Loc"),
					ActorCenterLocation);
				MeshComponents.SetScalarParameterValueOnMaterials(FName(f"Dissolve_Radius"), GrowthSphereMaskRadius);
			}
		}
	}

	UFUNCTION(DevFunction)
	void StartGrowing()
	{
		if (bHasBeenActivated)
			return;

		bHasBeenActivated = true;

		FVector Origin, Extent;
		GetActorBounds(false, Origin, Extent, true);
		GrowthSphereMaskRadius = Bounds * 1.2;
		bIsGrowing = true;
		HitBox.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
		MeshComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);

		BP_StormChaseMetalVineMelted();
	}

	UFUNCTION(BlueprintEvent)
	void BP_StormChaseMetalVineMelted()
	{
	}

	UFUNCTION(DevFunction)
	void StartDissolvingFromLocation(FVector WorldLocation)
	{
		bIsGrowing = false;
		auto DissolveSphere = SpawnActor(AAcidDissolveSphere, WorldLocation);
		DissolveSphere.ActorToMaskCollision = this;
		DissolveSphere.CurrentGrowthSpeed = 1000;
		DissolveSphere.GrowthSpeedChangeFactor = 0;
		DissolveSpheres.Add(DissolveSphere);
	}

	void UpdateNiagaraDissolve(TArray<FVector> Locations, TArray<float32> Radi)
	{
		if (Locations.Num() == 0)
			return;

		for (auto IterNiagara : NiagaraComps)
		{

			// PrintToScreen("Locations: " + Locations[0]);
			// PrintToScreen("Radii: " + Radi[0]);

			TArray<FVector> LocalSpaceLocation;
			LocalSpaceLocation.Reserve(Locations.Num());
			for (const FVector& IterLocations : Locations)
			{
				LocalSpaceLocation.Add(IterNiagara.GetWorldTransform().InverseTransformPosition(IterLocations));
			}

			NiagaraDataInterfaceArray::SetNiagaraArrayVector(IterNiagara, n"DissolveLocations", LocalSpaceLocation);
			NiagaraDataInterfaceArray::SetNiagaraArrayFloat(IterNiagara, n"DissolveRadii", Radi);
		}

		if (bNiagaraActivated == false)
		{
			for (auto IterNiagara : NiagaraComps)
			{
				IterNiagara.Activate();
			}
			bNiagaraActivated = true;
		}
	}

	bool bNiagaraActivated = false;
};