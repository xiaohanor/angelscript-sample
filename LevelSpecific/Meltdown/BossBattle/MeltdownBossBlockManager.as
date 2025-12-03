class AMeltdownBossBlockManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UMeltdownBossBlockComponent BlockZone;

	UPROPERTY(EditAnywhere)
	APlayerTrigger PlayerTrigger;

	UPROPERTY(EditAnywhere)
	TArray<AMeltdownBossBlockMover> BlockMovers;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

#if EDITOR
	UFUNCTION(CallInEditor, Category = "Block Zone")
	void GatherBlockMoversInZone()
	{
		BlockMovers.Reset();

		TArray<AMeltdownBossBlockMover> ActorsInLevel = Editor::GetAllEditorWorldActorsOfClass(AMeltdownBossBlockMover);
		for(auto Actor : ActorsInLevel)
		{
			if(BlockZone.Shape.IsPointInside(BlockZone.WorldTransform, Actor.ActorLocation))
			{
				auto Mover = Cast<AMeltdownBossBlockMover>(Actor);
				BlockMovers.Add(Mover);
			}
		}
	}
#endif
};

class UMeltdownBossBlockComponent : USceneComponent
{
	UPROPERTY(EditAnywhere, Category = "Block Zone")
	FHazeShapeSettings Shape = FHazeShapeSettings::MakeBox(FVector(500));
}

#if EDITOR
class UMeltdownBossBlockComponentVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UMeltdownBossBlockComponent;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        UMeltdownBossBlockComponent Comp = Cast<UMeltdownBossBlockComponent>(Component);
        if (!ensure((Comp != nullptr) && (Comp.GetOwner() != nullptr)))
            return;

		SetRenderForeground(false);
        VisualizeShape(Comp, Comp.Shape, FTransform::Identity, FLinearColor::Gray, 2.0);
		VisualiseConnections(Comp, FLinearColor::Red, 5);
    }   

    void VisualizeShape(UMeltdownBossBlockComponent Comp, FHazeShapeSettings Shape, FTransform Transform, FLinearColor Color, float Thickness)
    {
        FVector CenterPos = Comp.WorldTransform.TransformPosition(Transform.Location);
		FQuat WorldRotation = Comp.WorldTransform.TransformRotation(Transform.Rotation);
        FVector Scale = Transform.GetScale3D() * Comp.WorldScale;

        switch (Shape.Type)
        {
            case EHazeShapeType::Box:
                DrawWireBox(CenterPos, Scale * Shape.BoxExtents, WorldRotation, FLinearColor::Red, Thickness, bScreenSpace = true);
            break;
            case EHazeShapeType::Sphere:
                DrawWireSphere(CenterPos, Scale.Max * Shape.SphereRadius, FLinearColor::Red, Thickness, bScreenSpace = true);
            break;
            case EHazeShapeType::Capsule:
                DrawWireCapsule(CenterPos, Transform.Rotator(), FLinearColor::Red, Shape.CapsuleRadius * Scale.Max, Shape.CapsuleHalfHeight * Scale.Max, Thickness = Thickness, bScreenSpace = true);
            break;
            case EHazeShapeType::None:
            break;
        }
    }
	
	void VisualiseConnections(UMeltdownBossBlockComponent Comp, FLinearColor LineColor, float Thickness)
	{
		auto Owner = Cast<AMeltdownBossBlockManager>(Comp.Owner);

		if(Owner == nullptr)
			return;
		
		for(auto Metal : Owner.BlockMovers)
		{
			if(Metal == nullptr)
				continue;

			DrawLine(Comp.Owner.ActorLocation, Metal.ActorLocation, LineColor, Thickness);
		}
	}
} 
#endif