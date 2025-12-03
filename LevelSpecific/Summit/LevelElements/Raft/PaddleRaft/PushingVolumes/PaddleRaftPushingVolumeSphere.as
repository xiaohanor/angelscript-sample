class APaddleRaftPushingVolumeSphere : APaddleRaftPushingVolumeBase
{
	UPROPERTY(EditAnywhere)
	float ForceAttenuationRadius = 400;

	UPROPERTY(EditAnywhere)
	float OverlapRadius = 800;

	UPROPERTY(DefaultComponent, NotVisible, Attach = Root)
	USphereComponent SphereComp;
	default SphereComp.SetCollisionProfileName(n"Trigger");
	default SphereComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Overlap);
	default SphereComp.bGenerateOverlapEvents = true;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		SphereComp.SphereRadius = OverlapRadius;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		SphereComp.OnComponentBeginOverlap.AddUFunction(this, n"OnBeginOverlap");
		SphereComp.OnComponentEndOverlap.AddUFunction(this, n"OnEndOverlap");
	}

	FVector GetForceAtPointInOverlap(FVector WorldLocation) override
	{
		FVector Force = FVector::ZeroVector;
		FVector ToActor = (WorldLocation - ActorLocation);
		float Size = ToActor.Size2D();
		float Alpha = 1 - Math::Saturate(Size / ForceAttenuationRadius);
		Force = ToActor.GetSafeNormal() * MaxForceSize * Alpha;
		//Debug::DrawDebugDirectionArrow(ActorLocation, Force.GetSafeNormal(), Force.Size(), 50, FLinearColor::Red, 5);
		return Force;
	}

	#if EDITOR
		UFUNCTION(BlueprintOverride)
		void OnVisualizeInEditor() const
		{
			Debug::DrawDebugSphere(ActorLocation, OverlapRadius, 12, FLinearColor::White, 2);
			Debug::DrawDebugSphere(ActorLocation, ForceAttenuationRadius, 12, FLinearColor::Yellow, 2);
			for (int i = 0; i < 12; i++)
			{
				float YawRotation = 360.0 / 12.0 * i;
				FRotator Rotation = FRotator(0, YawRotation, 0);
				Rotation = ActorTransform.TransformRotation(Rotation);
				Debug::DrawDebugDirectionArrow(ActorLocation, Rotation.ForwardVector, ForceAttenuationRadius, 40, FLinearColor::Red, 10);
			}
		}
	#endif
}
