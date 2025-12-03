class ASkylineScrollingGeo : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.Mobility = EComponentMobility::Static;

	UPROPERTY(DefaultComponent)
	UBillboardComponent Billbord;

	TArray<USceneComponent>	SegmentRoots;

	float CurrentScrollingValue = 0.0;

	UPROPERTY(EditAnywhere)
	float ScrollingDistance = 2000.0;

	UPROPERTY(EditAnywhere)
	float ScrollingSpeed = 500.0;

	UPROPERTY(EditAnywhere)
	int Segments = 3;

	UPROPERTY(EditAnywhere)
	FVector ScrollingDirection = FVector(-1.0, 0.0, 0.0);

	UPROPERTY()
	UStaticMesh DebugMesh;

	UPROPERTY()
	UMaterialInterface DebugMaterial;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		UStaticMeshComponent DebugPlaneA = Cast<UStaticMeshComponent>(CreateComponent(UStaticMeshComponent));
		UStaticMeshComponent DebugPlaneB = Cast<UStaticMeshComponent>(CreateComponent(UStaticMeshComponent));
	
		DebugPlaneA.SetStaticMesh(DebugMesh);
		DebugPlaneB.SetStaticMesh(DebugMesh);

		DebugPlaneA.SetMaterial(0, DebugMaterial);
		DebugPlaneB.SetMaterial(0, DebugMaterial);

		DebugPlaneA.SetRelativeRotation(FRotator(90.0, 0.0, 0.0));
		DebugPlaneB.SetRelativeRotation(FRotator(90.0, 0.0, 0.0));

		DebugPlaneA.SetRelativeScale3D(FVector::OneVector * 20.0);
		DebugPlaneB.SetRelativeScale3D(FVector::OneVector * 20.0);

		DebugPlaneA.SetRelativeLocation(ScrollingDirection * -ScrollingDistance * 0.5);
		DebugPlaneB.SetRelativeLocation(ScrollingDirection * ScrollingDistance * 0.5);

		DebugPlaneA.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		DebugPlaneB.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		DebugPlaneA.SetHiddenInGame(true);
		DebugPlaneB.SetHiddenInGame(true);

		DebugPlaneA.bCanEverAffectNavigation = false;
		DebugPlaneB.bCanEverAffectNavigation = false;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);

		TArray<UStaticMeshComponent> StaticMeshComponents;

		// Get all StaticMeshComponents from attaced actors
		for (auto AttachedActor : AttachedActors)
		{
			TArray<UStaticMeshComponent> StaticMeshComponentsToAdd;
			AttachedActor.GetComponentsByClass(StaticMeshComponentsToAdd);
			StaticMeshComponents.Append(StaticMeshComponentsToAdd);
		
			AttachedActor.SetActorEnableCollision(false);
			AttachedActor.SetActorHiddenInGame(true);
		}

		// PrintToScreen("StaticMeshComponents = " + StaticMeshComponents.Num(), 5.0, FLinearColor::Green);

		// Create clone meshes
		for (int i = 0; i < Segments ; i++)
		{
			USceneComponent NewSegment = CreateScrollingSegment(StaticMeshComponents);
			NewSegment.SetRelativeLocation(ActorForwardVector * ScrollingDistance * i);
			SegmentRoots.Add(NewSegment);
		}

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		CurrentScrollingValue =  Math::Wrap(CurrentScrollingValue + ScrollingSpeed * DeltaSeconds, 0.0, ScrollingDistance);

		for (int i = 0; i < Segments ; i++)
			SegmentRoots[i].SetRelativeLocation(ScrollingDirection * Math::Wrap(CurrentScrollingValue + ScrollingDistance * i, -ScrollingDistance * Segments * 0.5, ScrollingDistance * Segments * 0.5));
	}

	UFUNCTION()
	USceneComponent CreateScrollingSegment(TArray<UStaticMeshComponent> StaticMeshComponents)
	{
		auto NewSegmentRoot = Cast<USceneComponent>(CreateComponent(USceneComponent));

		for(auto StaticMeshComponent : StaticMeshComponents)
		{
			UStaticMeshComponent NewComp = Cast<UStaticMeshComponent>(CreateComponent(UStaticMeshComponent));
			NewComp.SetStaticMesh(StaticMeshComponent.StaticMesh);
			NewComp.AttachToComponent(NewSegmentRoot);
			NewComp.SetRelativeTransform(StaticMeshComponent.WorldTransform.GetRelativeTransform(ActorTransform));
			NewComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

			for (int i = 0; i < NewComp.NumMaterials; i++)
			{
				NewComp.SetMaterial(i, StaticMeshComponent.GetMaterial(i));
			}
		}

		return NewSegmentRoot;
	}

}