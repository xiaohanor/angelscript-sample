class UPrisonBossDonutSplineMeshComponent : USplineMeshComponent
{
	default Mobility = EComponentMobility::Movable;
}

UCLASS(Abstract)
class APrisonBossDonutAttack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent DonutRoot;

	FHazeRuntimeSpline RuntimeSpline;

	FHazeAcceleratedFloat AccRadiusSpeedMultiplier;

	float CurrentRadius = 50.0;

	UPROPERTY(BlueprintReadOnly)
	TArray<USplineMeshComponent> SplineMeshComponents;

	float DesiredMeshLength = 1000.0;

	UPROPERTY(EditDefaultsOnly)
	UStaticMesh Mesh;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface Material;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDamageEffect> DamageEffect;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	float MeshScale = 0.5;

	int NumOfMeshes;
	float MeshLength;

	float CurrentSpawnFraction = 0.0;
	bool bFullySpawned = false;

	bool bDissipating = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RuntimeSpline.AddPoint(ActorLocation + ActorForwardVector * PrisonBoss::DonutMaxRadius);
		RuntimeSpline.AddPoint(ActorLocation + (ActorForwardVector + ActorRightVector).GetSafeNormal() * PrisonBoss::DonutMaxRadius);
		RuntimeSpline.AddPoint(ActorLocation + ActorRightVector * PrisonBoss::DonutMaxRadius);
		RuntimeSpline.AddPoint(ActorLocation + (-ActorForwardVector + ActorRightVector).GetSafeNormal() * PrisonBoss::DonutMaxRadius);
		RuntimeSpline.AddPoint(ActorLocation - ActorForwardVector * PrisonBoss::DonutMaxRadius);
		RuntimeSpline.AddPoint(ActorLocation + (-ActorForwardVector - ActorRightVector).GetSafeNormal() * PrisonBoss::DonutMaxRadius);
		RuntimeSpline.AddPoint(ActorLocation - ActorRightVector * PrisonBoss::DonutMaxRadius);
		RuntimeSpline.AddPoint(ActorLocation + (ActorForwardVector - ActorRightVector).GetSafeNormal() * PrisonBoss::DonutMaxRadius);
		RuntimeSpline.AddPoint(ActorLocation + ActorForwardVector * PrisonBoss::DonutMaxRadius);

		SplineMeshComponents.Reset();
		CreateSplineMeshes();
		UpdateSplineMeshes();

		UPrisonBossDonutEffectEventHandler::Trigger_Spawn(this);
	}

	void UpdateSpawnFraction(float Fraction)
	{
		CurrentSpawnFraction = Fraction;
		CurrentRadius = Math::Lerp(PrisonBoss::DonutSpawnMinRadius, PrisonBoss::DonutSpawnMaxRadius, CurrentSpawnFraction);
	}

	void FullySpawned()
	{
		bFullySpawned = true;
		DetachFromActor(EDetachmentRule::KeepWorld);

		UPrisonBossDonutEffectEventHandler::Trigger_FullySpawned(this);
	}

	void CreateSplineMeshes()
	{
		NumOfMeshes = Math::FloorToInt(RuntimeSpline.Length / DesiredMeshLength);
		MeshLength = RuntimeSpline.Length / NumOfMeshes;

		for (int i = 0; i < NumOfMeshes; i++)
		{
			auto SplineMesh = UPrisonBossDonutSplineMeshComponent::Create(this);
			SplineMesh.SetMobility(EComponentMobility::Movable);
			SplineMesh.StaticMesh = Mesh;
			for (int j = 0; j < SplineMesh.NumMaterials; j++)
				SplineMesh.SetMaterial(j, Material);
			SplineMeshComponents.Add(SplineMesh);

			SplineMesh.SetHiddenInGame(true);
		}
	}

	void UpdateSplineMeshes()
	{
		if (NumOfMeshes == 0)
			return;

		MeshLength = RuntimeSpline.Length / NumOfMeshes;

		for (int i = 0; i < SplineMeshComponents.Num(); i++)
		{
			FVector StartLocation;
			FRotator StartRotation;
			RuntimeSpline.GetLocationAndRotationAtDistance(RuntimeSpline.Length - ((i + 1) * MeshLength), StartLocation, StartRotation);

			FVector EndLocation;
			FRotator EndRotation;
			RuntimeSpline.GetLocationAndRotationAtDistance(RuntimeSpline.Length - (i * MeshLength), EndLocation, EndRotation);

			FRotator MidRotation = RuntimeSpline.GetRotationAtDistance(RuntimeSpline.Length - (i * MeshLength) + MeshLength * 0.5);

			auto SplineMeshComponent = SplineMeshComponents[i];

			SplineMeshComponent.SetStartAndEnd(
				SplineMeshComponent.WorldTransform.InverseTransformPosition(StartLocation),
				SplineMeshComponent.WorldTransform.InverseTransformVector(StartRotation.ForwardVector * MeshLength),
				SplineMeshComponent.WorldTransform.InverseTransformPosition(EndLocation),
				SplineMeshComponent.WorldTransform.InverseTransformVector(EndRotation.ForwardVector * MeshLength),
				false
			);

			SplineMeshComponent.SetStartScale(FVector2D(MeshScale, MeshScale), false);
			SplineMeshComponent.SetEndScale(FVector2D(MeshScale, MeshScale), false);
		
			// UpDir Roll
			SplineMeshComponent.SetSplineUpDir(StartRotation.UpVector);
			SplineMeshComponent.SetStartRoll(Math::DegreesToRadians((StartRotation.Compose(MidRotation.Inverse)).Roll), false);
			SplineMeshComponent.SetEndRoll(Math::DegreesToRadians((EndRotation.Compose(MidRotation.Inverse)).Roll), false);
		
			SplineMeshComponent.UpdateMesh(false);

			if ((Math::TruncToFloat(i)/Math::TruncToFloat(SplineMeshComponents.Num())) >= CurrentSpawnFraction)
				SplineMeshComponents[i].SetHiddenInGame(true);
			else
				SplineMeshComponents[i].SetHiddenInGame(false);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bFullySpawned)
		{
			AccRadiusSpeedMultiplier.AccelerateTo(1.0, 2.0, DeltaTime);
			CurrentRadius += AccRadiusSpeedMultiplier.Value * PrisonBoss::DonutRadiusIncreaseSpeed * DeltaTime;
		}
		// Debug::DrawDebugCylinder(ActorLocation, ActorLocation, CurrentRadius, 36, FLinearColor::Purple, 100.0);

		if (CurrentRadius >= PrisonBoss::DonutMaxRadius)
			Dissipate();

		RuntimeSpline.SetCustomCurvature(1.0);
		RuntimeSpline.SetPoint(ActorLocation + ActorForwardVector * CurrentRadius, 0);
		RuntimeSpline.SetPoint(ActorLocation + (ActorForwardVector + ActorRightVector).GetSafeNormal() * CurrentRadius, 1);
		RuntimeSpline.SetPoint(ActorLocation + ActorRightVector * CurrentRadius, 2);
		RuntimeSpline.SetPoint(ActorLocation + (-ActorForwardVector + ActorRightVector).GetSafeNormal() * CurrentRadius, 3);
		RuntimeSpline.SetPoint(ActorLocation - ActorForwardVector * CurrentRadius, 4);
		RuntimeSpline.SetPoint(ActorLocation + (-ActorForwardVector - ActorRightVector).GetSafeNormal() * CurrentRadius, 5);
		RuntimeSpline.SetPoint(ActorLocation - ActorRightVector * CurrentRadius, 6);
		RuntimeSpline.SetPoint(ActorLocation + (ActorForwardVector - ActorRightVector).GetSafeNormal() * CurrentRadius, 7);
		RuntimeSpline.SetPoint(ActorLocation + ActorForwardVector * CurrentRadius, 8);

		RuntimeSpline.SetCustomExitTangentPoint(RuntimeSpline.Points[0] + (ActorRightVector * 50.0));
		RuntimeSpline.SetCustomEnterTangentPoint(RuntimeSpline.Points[0] - (ActorRightVector * 50.0));
		UpdateSplineMeshes();

		if (!bDissipating)
		{
			for (AHazePlayerCharacter Player : Game::GetPlayers())
			{
				float Dist = (Player.GetActorCenterLocation() - ActorLocation).Size();
				float VerticalDist = Player.ActorCenterLocation.Z - ActorLocation.Z;

				if (Math::IsNearlyEqual(Dist, CurrentRadius, 50.0))
				{
					if (Math::Abs(VerticalDist) <= 80.0)
					{
						FVector DeathDir = (Player.ActorLocation - ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
						Player.DamagePlayerHealth(0.5, FPlayerDeathDamageParams(DeathDir), DamageEffect, DeathEffect);
					}
				}
			}
		}
	}

	void Dissipate()
	{
		if (bDissipating)
			return;

		bDissipating = true;
		BP_Dissipate();
		UPrisonBossDonutEffectEventHandler::Trigger_Dissipate(this);

		Timer::SetTimer(this, n"Destroy", 0.5);
	}

	UFUNCTION()
	private void Destroy()
	{
		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Dissipate() {}
}