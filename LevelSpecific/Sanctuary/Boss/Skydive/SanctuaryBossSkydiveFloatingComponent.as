class USanctuarySkydiveFloatingComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USanctuarySkydiveFloatingComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(UActorComponent Component)
	{
		auto FloatingComponent = Cast<USanctuarySkydiveFloatingComponent>(Component);
	
		if (FloatingComponent.SkydiveActor == nullptr || FloatingComponent.SkydiveActor.SplineActor == nullptr)
			return;

		FVector Location = FloatingComponent.SkydiveActor.SplineActor.Spline.GetWorldLocationAtSplineDistance(FloatingComponent.PreviewDistance);

		DrawPoint(Location, FLinearColor::Green, 100.0);
	}
}

class USanctuarySkydiveFloatingComponent : USceneComponent
{
	UPROPERTY(EditAnywhere)
	TArray<FSanctuaryFloatingData> FloatingData;

	UPROPERTY(EditAnywhere)
	bool bReattachChildrenToThis = true;

	UPROPERTY(EditAnywhere)
	bool bWorldSpace = false;

	UPROPERTY(EditAnywhere)
	float BlendInTime = 2.0;

	FHazeAcceleratedFloat AcceleratedFloat;
	default AcceleratedFloat.Value = 1.0;
 
	UDarkPortalResponseComponent DarkPortalResponseComponent;

	UPROPERTY(EditAnywhere)
	ASanctuaryBossSkydiveActor SkydiveActor;

	float PreviewDistance = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (bReattachChildrenToThis)
		{
			TArray<AActor> AttachedActors;
			Owner.GetAttachedActors(AttachedActors);
			for (auto AttachedActor : AttachedActors)
				AttachedActor.AttachToComponent(this, AttachmentRule = EAttachmentRule::KeepRelative);
		}

		DarkPortalResponseComponent = UDarkPortalResponseComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float Alpha = 1.0;
		if (DarkPortalResponseComponent != nullptr)
			Alpha = (DarkPortalResponseComponent.IsReceivingForce() ? 0.0 : 1.0);

		AcceleratedFloat.AccelerateTo(Alpha, BlendInTime, DeltaSeconds);
	
		Update(SkydiveActor.SplinePosition.CurrentSplineDistance * 0.001);
	}

	void Update(float Time)
	{
		FTransform Transform;

		for (auto Data : FloatingData)
		{	
			if (Data.bRotation)
				if (Data.bConstantRotation)
					Transform.Rotation = Transform.Rotation * FQuat(Data.Axis.GetSafeNormal(), Time * Data.Rate * PI);
				else
					Transform.Rotation = Transform.Rotation * FQuat(Data.Axis.GetSafeNormal(), Math::Sin((Time * Data.Rate) + Data.Offset) * Math::DegreesToRadians(Data.Axis.Size()));
			else
				Transform.Location = Transform.Location + Data.Axis * Math::Sin((Time * Data.Rate) + Data.Offset);
		}

		RelativeTransform = LerpTransform(FTransform::Identity, Transform, AcceleratedFloat.Value);
	}

	FTransform LerpTransform(FTransform A, FTransform B, float Alpha)
	{
		FTransform Transform;
		Transform.Location = Math::Lerp(A.Location, B.Location, Alpha);
		Transform.Rotation = FQuat::Slerp(A.Rotation, B.Rotation, Alpha);
		Transform.Scale3D = Math::Lerp(A.Scale3D, B.Scale3D, Alpha);
		
		return Transform;
	}
}