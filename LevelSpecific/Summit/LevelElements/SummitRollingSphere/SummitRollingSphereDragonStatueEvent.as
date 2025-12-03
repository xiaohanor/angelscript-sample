class USummitRollingSphereDragonStatueEventComponent : USceneComponent
{
	UPROPERTY(EditAnywhere, Category = "Settings")
	FHazeShapeSettings StatueGatherZone;
	default StatueGatherZone.Type = EHazeShapeType::Sphere;
	default StatueGatherZone.SphereRadius = 2000;
};

class ASummitRollingSphereDragonStatueEvent : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent, ShowOnActor)
	USummitRollingSphereDragonStatueEventComponent Root;

	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;

	UPROPERTY(EditAnywhere, Category = "Settings")
	TArray<ASummitRollingSphereDragonStatue> Statues;

	UPROPERTY(DefaultComponent)
	USceneComponent EventLookAtLocation;

	TArray<FQuat> StatuesStartRotations;
	TArray<FQuat> StatueEndRotations;
	TArray<UMaterialInstanceDynamic> MaterialInstances;
	FLinearColor EmissiveStartColor;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float EventDuration = 2.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	FRuntimeFloatCurve RotationCurve;

	UPROPERTY(EditAnywhere, Category = "Settings")
	FRuntimeFloatCurve EmissiveCurve;

	float EventAlpha = 0.0;
	float EventTargetAlpha = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(Statues.Num() == 0)
			return;

		
		for(auto Statue : Statues)
		{
			if(Statue == nullptr)
			{
				Statues.RemoveSingleSwap(Statue);
			}

			StatuesStartRotations.Add(Statue.ActorRotation.Quaternion());

			FVector FlatEventLocation = EventLookAtLocation.WorldLocation;
			FlatEventLocation.Z = Statue.ActorLocation.Z;
			FVector DirToLocation = (FlatEventLocation - Statue.ActorLocation);
			FQuat EndRotation = FQuat::MakeFromYZ(DirToLocation, FVector::UpVector);
			StatueEndRotations.Add(EndRotation);

			auto StaticMesh = UStaticMeshComponent::Get(Statue);

			auto NewMaterial = StaticMesh.CreateDynamicMaterialInstance(1);
			EmissiveStartColor = NewMaterial.GetVectorParameterValue(n"EmissiveColor");

			NewMaterial.SetVectorParameterValue(n"EmissiveColor", FLinearColor(0,0,0,0));

			MaterialInstances.Add(NewMaterial);
		}
	}

	UFUNCTION(BlueprintCallable, CrumbFunction)
	void Crumb_StartDragonStatueTurn()
	{
		EventTargetAlpha = 1.0;
	}

	UFUNCTION(BlueprintCallable, CrumbFunction)
	void Crumb_StartDragonStatueTurnBack()
	{
		EventTargetAlpha = 0.0;
	}



	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(EventAlpha != EventTargetAlpha)
		{
			EventAlpha = Math::FInterpConstantTo(EventAlpha, EventTargetAlpha, DeltaSeconds, 1/EventDuration);
			EventAlpha = Math::Clamp(EventAlpha, 0, 1);

			UpdateRotation();
			UpdateEmissive();
		}
	}

	void UpdateRotation()
	{
		float RotationAlpha = RotationCurve.GetFloatValue(EventAlpha);

		for(int i = 0; i < Statues.Num(); i++)
		{
			FQuat StartRotation = StatuesStartRotations[i];
			FQuat EndRotation = StatueEndRotations[i];

			FQuat NewRotation = FQuat::Slerp(StartRotation, EndRotation, RotationAlpha);
			Statues[i].SetActorRotation(NewRotation);
		}
	}

	void UpdateEmissive()
	{
		float ColorAlpha = EmissiveCurve.GetFloatValue(EventAlpha);

		for(int i = 0; i < Statues.Num(); i++)
		{
			auto NewColor = FLinearColor::LerpUsingHSV(FLinearColor(0,0,0,0), EmissiveStartColor, ColorAlpha);
			MaterialInstances[i].SetVectorParameterValue(n"EmissiveColor", NewColor);
		}
	}

	UFUNCTION(CallInEditor, Category = "Settings")
	void SetStatuesInZone()
	{
		TArray<ASummitRollingSphereDragonStatue> StatueActorsInLevel = Editor::GetAllEditorWorldActorsOfClass(ASummitRollingSphereDragonStatue);
		Statues.Empty();

		for(auto StatueActor : StatueActorsInLevel)
		{
			if(Root.StatueGatherZone.IsPointInside(Root.WorldTransform, StatueActor.ActorLocation))
			{
				auto Statue = Cast<ASummitRollingSphereDragonStatue>(StatueActor);
				Statues.AddUnique(Statue);
			}
		}
	}
}

#if EDITOR
class USummitRollingSphereDragonStatueEventVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = USummitRollingSphereDragonStatueEventComponent;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        USummitRollingSphereDragonStatueEventComponent Comp = Cast<USummitRollingSphereDragonStatueEventComponent>(Component);
        if (!ensure((Comp != nullptr) && (Comp.GetOwner() != nullptr)))
            return;

		auto Event = Cast<ASummitRollingSphereDragonStatueEvent>(Comp.Owner);
		check(Event != nullptr);

		SetRenderForeground(false);
        VisualizeShape(Comp, Comp.StatueGatherZone, FTransform::Identity, 2.0);

		for(auto Statue : Event.Statues)
		{
			if(Statue == nullptr)
				continue;
			DrawLine(Statue.ActorLocation, Event.ActorLocation, FLinearColor::Red, 5);
		}
    }   

    void VisualizeShape(USummitRollingSphereDragonStatueEventComponent Comp, FHazeShapeSettings Shape, FTransform Transform, float Thickness)
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
			default: break;
        }
    }
} 
#endif