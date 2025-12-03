struct FSanctuaryFloatingData
{
	UPROPERTY()
	bool bRotation = false;
	
	UPROPERTY()
	bool bConstantRotation = false;

	UPROPERTY()
	FVector Axis;

	UPROPERTY()
	float Rate = 1.0;

	UPROPERTY()
	float Offset = 0.0;
}

class USanctuaryFloatingSceneComponent : USceneComponent
{
	UPROPERTY(EditAnywhere)
	TArray<FSanctuaryFloatingData> FloatingData;

	UPROPERTY(EditAnywhere)
	bool bReattachChildrenToThis = true;

	UPROPERTY(EditAnywhere)
	bool bWorldSpace = false;

	UPROPERTY(EditAnywhere)
	float BlendInTime = 2.0;

	UPROPERTY(EditAnywhere)
	bool bUseLocationOffset = false;

	float LocationOffset = 0.0;

	FHazeAcceleratedFloat AcceleratedFloat;

	bool bMegaPortalGrabbing = false;
 
	UDarkPortalResponseComponent DarkPortalResponseComponent;

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

		if (bUseLocationOffset)
			LocationOffset = WorldLocation.Size();

		AcceleratedFloat.SnapTo(1.0);

		if (AttachParent != nullptr)
			AddTickPrerequisiteComponent(AttachParent);

		FTransform PrevTransform = WorldTransform;
		SetAbsolute(true, true, true);
		WorldTransform = PrevTransform;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Mobility != EComponentMobility::Movable)
			return;

		float Alpha = 1.0;
		if (DarkPortalResponseComponent != nullptr)
			Alpha = (DarkPortalResponseComponent.IsReceivingForce() || bMegaPortalGrabbing ? 0.0 : 1.0);

		AcceleratedFloat.AccelerateTo(Alpha, BlendInTime, DeltaSeconds);

		UpdateTransform();

//		RelativeTransform = (bWorldSpace ? InverseTransform(AttachmentRoot.RelativeTransform, Transform) : Transform);
	}

	void UpdateTransform()
	{
		FTransform Transform;

		for (auto Data : FloatingData)
		{	
			if (Data.bRotation)
				if (Data.bConstantRotation)
					Transform.Rotation = Transform.Rotation * FQuat(Data.Axis.GetSafeNormal(), (Time::PredictedGlobalCrumbTrailTime + LocationOffset) * Data.Rate * PI);
				else
					Transform.Rotation = Transform.Rotation * FQuat(Data.Axis.GetSafeNormal(), Math::Sin(((Time::PredictedGlobalCrumbTrailTime + LocationOffset) * Data.Rate) + Data.Offset) * Math::DegreesToRadians(Data.Axis.Size()));
			else
				Transform.Location = Transform.Location + Data.Axis * Math::Sin(((Time::PredictedGlobalCrumbTrailTime + LocationOffset) * Data.Rate) + Data.Offset);
		}

//		Print("Alpha: " + AcceleratedFloat.Value, 0.0, FLinearColor::Green);
		FTransform ParentTransform;
		if (AttachParent != nullptr)
			ParentTransform = AttachParent.WorldTransform;

		WorldTransform = FTransform::ApplyRelative(
			ParentTransform,
			LerpTransform(FTransform::Identity, Transform, AcceleratedFloat.Value)
		);
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