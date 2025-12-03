class USanctuarySnakeTailSegmentComponent : UHazeSkeletalMeshComponentBase
{
	UPROPERTY(Category = "Animation")
	UAnimSequence Animation;

	UPROPERTY()
	UStaticMesh StaticMesh;

	UPROPERTY()
	FVector Scale = FVector(2.0, 2.0, 1.0);

	UPROPERTY()
	FVector RelativeOffset = FVector::UpVector * 80.0;

	UPROPERTY()
	UMaterialInterface MaterialOverride;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (StaticMesh == nullptr)
			return;

		UMaterialInterface Material;

		if (MaterialOverride != nullptr)
			Material = MaterialOverride;
		else
		{
			if (Materials.Num() == 0)
				Material = StaticMesh.GetMaterial(0);
			else
				Material = Materials[0];
		}

		auto StaticMeshComponent = UStaticMeshComponent::Create(Owner);
		StaticMeshComponent.StaticMesh = StaticMesh;
		StaticMeshComponent.AttachToComponent(this);
		StaticMeshComponent.WorldScale3D = Owner.ActorScale3D * Scale;
		StaticMeshComponent.RelativeLocation += RelativeOffset;
		StaticMeshComponent.SetMaterial(0, Material);
		StaticMeshComponent.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		auto Collison = UCapsuleComponent::Create(Owner);
		Collison.AttachToComponent(this);
		Collison.GenerateOverlapEvents = false;
		Collison.SetCapsuleHalfHeight(200.0);
		Collison.SetCapsuleRadius(100.0);
		Collison.RelativeLocation += FVector::UpVector * 50.0;
		Collison.RelativeRotation += FRotator(90.0, 0.0, 0.0);
		Collison.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
		Collison.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceEnemy, ECollisionResponse::ECR_Block);
	}
}