class USkylineBossProximityMineZoneVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USkylineBossProximityMineZoneVisualizerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent InComponent)
	{
		auto MineZone = Cast<ASkylineBossProximityMineZone>(InComponent.Owner);

		for (auto TargetLocation : MineZone.TargetLocations)
			DrawWireSphere(MineZone.ActorTransform.TransformPositionNoScale(TargetLocation), 300.0, FLinearColor::Red, 50.0, 12);

		DrawWireBox(MineZone.ActorLocation, MineZone.Bounds, MineZone.ActorQuat, FLinearColor::Red, 100.0);
	}
}

class USkylineBossProximityMineZoneVisualizerComponent : UActorComponent
{

}

class ASkylineBossProximityMineZone : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComponent;

	UPROPERTY(DefaultComponent)
	UBillboardComponent BillboardComponent;

	UPROPERTY(DefaultComponent)
	USkylineBossProximityMineZoneVisualizerComponent VisualizerComponent;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComponent;

	UPROPERTY(EditAnywhere)
	int NumberOfMines = 12;

	UPROPERTY(EditAnywhere, Meta = (MakeEditWidget))
	FVector Bounds;

	UPROPERTY(EditAnywhere)
	TArray<FVector>	TargetLocations;

	UPROPERTY(EditAnywhere)
	TSubclassOf<ASkylineBossProximityMine> MineClass;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
	}	

	UFUNCTION(CallInEditor)
	void CreateMineClusterTargets()
	{
		TargetLocations.Empty();
		for (int i = 0; i < NumberOfMines; i++)
		{
			FVector TargetLocation;
			TargetLocation.X = Math::RandRange(-Bounds.X, Bounds.X);
			TargetLocation.Y = Math::RandRange(-Bounds.Y, Bounds.Y);
			TargetLocation.Z = 1000.0;

			auto Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
			Trace.IgnoreActor(this);

			FVector TargetWorldLocation = ActorTransform.TransformPositionNoScale(TargetLocation);
			auto HitResult = Trace.QueryTraceSingle(TargetWorldLocation, TargetWorldLocation + FVector::UpVector * -10000.0);

			if (HitResult.bBlockingHit)
			{
				TargetWorldLocation = HitResult.ImpactPoint;
				TargetLocations.Add(ActorTransform.InverseTransformPositionNoScale(TargetWorldLocation));
			}		
		
		//	Debug::DrawDebugPoint(TargetWorldLocation, 100.0, FLinearColor::Green, 1.0);
		}
	}

	void SpawnMines()
	{
		for (auto TargetLocation : TargetLocations)
		{
			SpawnActor(MineClass, ActorTransform.TransformPositionNoScale(TargetLocation));
		}
	}
}