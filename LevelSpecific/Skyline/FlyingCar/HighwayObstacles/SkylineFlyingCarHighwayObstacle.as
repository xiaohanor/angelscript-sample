class ASkylineFlyingCarHighwayObstacle : AActorAlignedToSpline
{
#if EDITOR
	default bAlignLocationToSpline = true;
	default bAlignRotationToSpline = true;
	default bAlignScaleToSpline = false;
#endif

	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent)
	USkylineFlyingCarDestructibleComponent DestructibleComponent;

	UPROPERTY(DefaultComponent)
	USkylineFlyingCarGunResponseComponent GunResponseComponent;

	UPROPERTY(DefaultComponent)
	USkylineFlyingCarHighwayObstacleMaterialPierceComponent MaterialPierceComponent;

	UPROPERTY(EditDefaultsOnly)
	UStaticMesh Mesh;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface Material;

	UPROPERTY(EditDefaultsOnly)
	ESplineMeshAxis SplineMeshForwardAxis;
	default SplineMeshForwardAxis = ESplineMeshAxis::Z;

	UPROPERTY(EditAnywhere)
	float Length = 1000.0;

	// Maybe sample highway's spline mesh?
	UPROPERTY(EditAnywhere)
	float RadiusMultiplier = 32.0;


	UPROPERTY(EditInstanceOnly, Category = "Collision")
	FName CollisionProfileName = n"BlockAll";

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Super::ConstructionScript();

		if (!SplineActor.IsValid())
			return;

		UHazeSplineComponent Spline = UHazeSplineComponent::Get(SplineActor.Get());
		if (Spline == nullptr)
			return;

		// Create spline mesh component
		USplineMeshComponent SplineMesh = USplineMeshComponent::Create(this, n"SplineMesh");
		SplineMesh.ForwardAxis = SplineMeshForwardAxis;
		SplineMesh.SetStaticMesh(Mesh);
		SplineMesh.SetMaterial(0, Material);

		// Setup collision
		SplineMesh.SetCollisionProfileName(CollisionProfileName);

		const float StartSplineDistance = Spline.GetClosestSplineDistanceToWorldLocation(ActorLocation);
		const float EndSplineDistance = Math::Min(StartSplineDistance + Length, Spline.GetSplineLength());
		const float TangentSize = EndSplineDistance - StartSplineDistance;

		FVector StartPosition = Spline.GetWorldLocationAtSplineDistance(StartSplineDistance);
		StartPosition = RootComponent.RelativeTransform.InverseTransformPositionNoScale(StartPosition);
		SplineMesh.SetStartPosition(StartPosition);

		FVector StartTangent = Spline.GetWorldTangentAtSplineDistance(StartSplineDistance).GetSafeNormal() * TangentSize;
		StartTangent = RootComponent.RelativeTransform.InverseTransformVector(StartTangent);
		SplineMesh.SetStartTangent(StartTangent);

		SplineMesh.SetStartScale(FVector2D(RadiusMultiplier, RadiusMultiplier));

		FVector EndPosition = Spline.GetWorldLocationAtSplineDistance(EndSplineDistance);
		EndPosition = RootComponent.RelativeTransform.InverseTransformPositionNoScale(EndPosition);
		SplineMesh.SetEndPosition(EndPosition);

		FVector EndTangent = Spline.GetWorldTangentAtSplineDistance(EndSplineDistance).GetSafeNormal() * TangentSize;
		EndTangent = RootComponent.RelativeTransform.InverseTransformVectorNoScale(EndTangent);
		SplineMesh.SetEndTangent(EndTangent);

		SplineMesh.SetEndScale(FVector2D(RadiusMultiplier, RadiusMultiplier));
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Initialize material pierce component
		USplineMeshComponent SplineMesh = USplineMeshComponent::Get(this, n"SplineMesh");
		if (SplineMesh != nullptr)
			MaterialPierceComponent.Initialize(SplineMesh);

		// Bind events
		DestructibleComponent.OnHit.AddUFunction(this, n"OnHit");
		DestructibleComponent.OnDestroyed.AddUFunction(this, n"OnPwned");
	}
	
	UFUNCTION()
	private void OnHit(FSkylineFlyingCarGunHit HitInfo)
	{
		MaterialPierceComponent.TakeHit(HitInfo);
	}

	UFUNCTION()
	private void OnPwned(FSkylineFlyingCarGunHit LastHitInfo)
	{
		// Nice explosion effect
		// Niagara::SpawnOneShotNiagaraSystemAtLocation(, LastHitInfo.WorldImpactLocation);

		USplineMeshComponent SplineMesh = USplineMeshComponent::Get(this, n"SplineMesh");
		if (SplineMesh != nullptr)
		{
			SplineMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		}

		SetActorHiddenInGame(true);
	}
}