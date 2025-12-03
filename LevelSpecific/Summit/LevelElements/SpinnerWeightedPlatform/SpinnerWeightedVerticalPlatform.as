#if EDITOR
class USpinnerWeightedVerticalComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UVisualizeSpinnerWeightedVerticalComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(UActorComponent Component)
	{
		UVisualizeSpinnerWeightedVerticalComponent DummyComp = Cast<UVisualizeSpinnerWeightedVerticalComponent>(Component);

		ASpinnerWeightedVerticalPlatform WeightedPlatform = Cast<ASpinnerWeightedVerticalPlatform>(DummyComp.Owner);

		if (WeightedPlatform == nullptr)
			return;
		
		FVector StartLocation;
		float StartHeight;

		StartLocation = WeightedPlatform.ActorLocation; 
		StartHeight = WeightedPlatform.ActorLocation.Z;
		FVector EndLocation = StartLocation + FVector(0.0, 0.0, WeightedPlatform.MaxDistance);

		DrawLine(StartLocation, EndLocation, FLinearColor::LucBlue, 45.0);
		DrawCircle(EndLocation, 200.0, FLinearColor::LucBlue, 28.0);
	}
}
#endif

class UVisualizeSpinnerWeightedVerticalComponent : UActorComponent
{

}

struct FSpinnerVerticalMetalPositionRange
{
	float MinHeight;
	float MaxHeight;
	ANightQueenMetal MetalPiece;
}

class ASpinnerWeightedVerticalPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent PlatformRoot;
	default PlatformRoot.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	default PlatformRoot.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);
	// default PlatformRoot.SetSimulatePhysics(true);

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent DeactivatedLocation;
	default DeactivatedLocation.SetWorldScale3D(FVector(2.0));

	UPROPERTY(DefaultComponent)
	UDragonSpinnerResponseComponent SpinnerResponseComp;

	UPROPERTY(DefaultComponent)
	UPlayerInheritMovementComponent InheritMovement;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SpinnerWeightedMovementCapability");

	UPROPERTY(DefaultComponent)
	UVisualizeSpinnerWeightedVerticalComponent VisualizerDummyComp;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TArray<ANightQueenMetal> MetalBlockers;

	TArray<FSpinnerVerticalMetalPositionRange> MetalRanges;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float MaxDistance = 500.0;

	FVector StartLocation;
	
	float StartHeight;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = ActorCenterLocation; 
		StartHeight = ActorCenterLocation.Z;

		FVector Origin;
		FVector BoxExtents;
		GetActorBounds(true, Origin, BoxExtents);
		float OffsetHeight = BoxExtents.Z;

		for (ANightQueenMetal MetalBlocker : MetalBlockers)
		{
			float CenterHeight = MetalBlocker.ActorCenterLocation.Z - StartHeight;

			FSpinnerVerticalMetalPositionRange NewRange;
			FVector MetalBounding = MetalBlocker.GetActorBoxExtents(true);
			NewRange.MinHeight = CenterHeight - (MetalBounding.Z) - OffsetHeight; //Include own bounding volume offset
			NewRange.MaxHeight = CenterHeight + (MetalBounding.Z) + OffsetHeight;
			NewRange.MetalPiece = MetalBlocker;

			MetalRanges.Add(NewRange);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (ANightQueenMetal MetalBlocker : MetalBlockers)
		{
			Debug::DrawDebugSphere(MetalBlocker.ActorCenterLocation, 200.0, 12, FLinearColor::Red);
		}
	}

	float GetCurrentHeight() const
	{
		return ActorLocation.Z - StartHeight;
	}

	float GetProjectedHeight(FVector NewPosition) const
	{
		return NewPosition.Z - StartHeight;
	}

	float GetWithinMetalBoundsHeightDat(FVector NewPosition)
	{
		FSpinnerVerticalMetalPositionRange Data;

		float NextHeight = NewPosition.Z - StartHeight;

		//Finds the first range. Does not account for multiple stuck together
		for (FSpinnerVerticalMetalPositionRange Range : MetalRanges)
		{
			if (Range.MetalPiece.bMelted)
				continue;

			if (NextHeight > Range.MinHeight && NextHeight < Range.MaxHeight)
			{
				float AboveMin = NextHeight - Range.MinHeight;
				float BelowMax = NextHeight - Range.MaxHeight;
				return Math::Abs(AboveMin) < Math::Abs(BelowMax) ? Range.MinHeight : Range.MaxHeight;
			}
		}

		return 0.0;
	}
}