
struct FAcidHit
{
	UPROPERTY()
	FVector ImpactLocation;

	UPROPERTY()
	FVector ImpactNormal;

	UPROPERTY()
	UPrimitiveComponent HitComponent;

	UPROPERTY()
	AHazeActor PlayerInstigator;

	UPROPERTY()
	float Damage = 0.0;
};

event void FOnAcidChange();
event void FOnAcidTick(float DeltaTime);
event void FOnAcidHit(FAcidHit Hit);

class UAcidResponseComponent : USceneComponent
{
	access AcidInternal = private, UAcidManagerComponent;

	// Shape of the area that can be hit by acid
	UPROPERTY(EditAnywhere)
	FHazeShapeSettings Shape;

	// Called on frames where this object is inside acid and being damaged
	UPROPERTY()
	FOnAcidTick OnAcidTick;

	// Called when the object is inside acid when it wasn't before
	UPROPERTY()
	FOnAcidChange OnBeginInsideAcid;

	// Called when the object is no longer inside acid when it was before
	UPROPERTY()
	FOnAcidChange OnEndInsideAcid;

	// Called when this object is hit directly by acid
	UPROPERTY()
	FOnAcidHit OnAcidHit;

	UPROPERTY()
	bool bIsPrimitiveParentExclusive = false;

	// USceneComponent AttachedToComponent;

	access:AcidInternal
	bool bInsideAcid = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (Shape.IsZeroSize())
			SetComponentTickEnabled(false);

		// AttachedToComponent = GetAttachParent();
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		UpdateInsideAcid();
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	void CrumbActivateAcidHit(FAcidHit Hit)
	{
		OnAcidHit.Broadcast(Hit);
	}

	access:AcidInternal
	void UpdateInsideAcid()
	{
		if (Shape.IsZeroSize())
			return;

		bool bNewInside = Acid::IsAcidInsideShape(Shape, WorldTransform);
		if (bInsideAcid && !bNewInside)
		{
			SetComponentTickInterval(Math::RandRange(0.0, 0.2));

			bInsideAcid = false;
			OnEndInsideAcid.Broadcast();
		}
		else if (!bInsideAcid && bNewInside)
		{
			SetComponentTickInterval(0.0);

			bInsideAcid = true;
			OnBeginInsideAcid.Broadcast();
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Update whether we're inside any acid
		UpdateInsideAcid();

		if (bInsideAcid)
		{
			// Tick decay from the acid
			OnAcidTick.Broadcast(DeltaSeconds);
		}
		else
		{
			// Fix the interval after we randomized it earlier
			SetComponentTickInterval(0.2);
		}
	}
};

#if EDITOR
class UAcidResponseComponentVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UAcidResponseComponent;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        UAcidResponseComponent Comp = Cast<UAcidResponseComponent>(Component);
        if (!ensure((Comp != nullptr) && (Comp.GetOwner() != nullptr)))
            return;

		SetRenderForeground(true);
        VisualizeShape(Comp, Comp.Shape, FTransform::Identity, FLinearColor::Green, 3.0);
    }   

    void VisualizeShape(UAcidResponseComponent Comp, FHazeShapeSettings Shape, FTransform Transform, FLinearColor Color, float Thickness)
    {
        FVector CenterPos = Comp.WorldTransform.TransformPosition(Transform.Location);
		FQuat WorldRotation = Comp.WorldTransform.TransformRotation(Transform.Rotation);
        FVector Scale = Transform.GetScale3D() * Comp.WorldScale;

        switch (Shape.Type)
        {
            case EHazeShapeType::Box:
                DrawWireBox(CenterPos, Scale * Shape.BoxExtents, WorldRotation, Color, Thickness, bScreenSpace = true);
            break;
            case EHazeShapeType::Sphere:
                DrawWireSphere(CenterPos, Scale.Max * Shape.SphereRadius, Color, Thickness, bScreenSpace = true);
            break;
            case EHazeShapeType::Capsule:
                DrawWireCapsule(CenterPos, Transform.Rotator(), Color, Shape.CapsuleRadius * Scale.Max, Shape.CapsuleHalfHeight * Scale.Max, 24, Thickness, true);
            break;
			default : break;
        }
    }
} 
#endif