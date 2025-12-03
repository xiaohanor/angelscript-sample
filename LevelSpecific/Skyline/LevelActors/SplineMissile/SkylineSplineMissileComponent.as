class USkylineSplineMissileComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USkylineSplineMissileComponent;

	bool bIsHandleSelected = false;

	float CoordSystemArrowLength = 100.0;
	float CoordSystemArrowThickness = 5.0;
	float CoordSystemArrowSize = 10.0;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent InComponent)
	{
		auto SkylineSplineMissileComp = Cast<USkylineSplineMissileComponent>(InComponent);

		if (SkylineSplineMissileComp.bPinTargetTransform)
			SkylineSplineMissileComp.TargetTransform = SkylineSplineMissileComp.PinnedTransform.GetRelativeTransform(SkylineSplineMissileComp.WorldTransform);

		// Origin
		/*
		DrawArrow(SkylineSplineMissileComp.WorldTransform.Location, SkylineSplineMissileComp.WorldTransform.Location + SkylineSplineMissileComp.WorldTransform.Rotation.ForwardVector * CoordSystemArrowLength, FLinearColor::Red, CoordSystemArrowSize, CoordSystemArrowThickness);
		DrawArrow(SkylineSplineMissileComp.WorldTransform.Location, SkylineSplineMissileComp.WorldTransform.Location + SkylineSplineMissileComp.WorldTransform.Rotation.RightVector * CoordSystemArrowLength, FLinearColor::Green, CoordSystemArrowSize, CoordSystemArrowThickness);
		DrawArrow(SkylineSplineMissileComp.WorldTransform.Location, SkylineSplineMissileComp.WorldTransform.Location + SkylineSplineMissileComp.WorldTransform.Rotation.UpVector * CoordSystemArrowLength, FLinearColor::Blue, CoordSystemArrowSize, CoordSystemArrowThickness);
		*/

		SetHitProxy(n"TransformHandle", EVisualizerCursor::CardinalCross);
			DrawArrow(SkylineSplineMissileComp.TargetWorldTransform.Location, SkylineSplineMissileComp.TargetWorldTransform.Location + SkylineSplineMissileComp.TargetWorldTransform.Rotation.ForwardVector * CoordSystemArrowLength, FLinearColor::Red, CoordSystemArrowSize, CoordSystemArrowThickness);
			DrawArrow(SkylineSplineMissileComp.TargetWorldTransform.Location, SkylineSplineMissileComp.TargetWorldTransform.Location + SkylineSplineMissileComp.TargetWorldTransform.Rotation.RightVector * CoordSystemArrowLength, FLinearColor::Green, CoordSystemArrowSize, CoordSystemArrowThickness);
			DrawArrow(SkylineSplineMissileComp.TargetWorldTransform.Location, SkylineSplineMissileComp.TargetWorldTransform.Location + SkylineSplineMissileComp.TargetWorldTransform.Rotation.UpVector * CoordSystemArrowLength, FLinearColor::Blue, CoordSystemArrowSize, CoordSystemArrowThickness);
		ClearHitProxy();

		for (int i = 0; i < SkylineSplineMissileComp.AdditionalPoints.Num(); i++)
		{
			SetHitProxy(FName("AdditionalPoint_" + i), EVisualizerCursor::CardinalCross);
				DrawPoint(SkylineSplineMissileComp.AdditionalPoints[i].Location, FLinearColor::Green, 100.0);
//				DrawArrow(SkylineSplineMissileComp.AdditionalPoints[i].Location, SkylineSplineMissileComp.AdditionalPoints[i].Location + SkylineSplineMissileComp.TargetWorldTransform.Rotation.ForwardVector * CoordSystemArrowLength, FLinearColor::Red, CoordSystemArrowSize, CoordSystemArrowThickness);
//				DrawArrow(SkylineSplineMissileComp.AdditionalPoints[i].Location, SkylineSplineMissileComp.AdditionalPoints[i].Location + SkylineSplineMissileComp.TargetWorldTransform.Rotation.RightVector * CoordSystemArrowLength, FLinearColor::Green, CoordSystemArrowSize, CoordSystemArrowThickness);
				DrawArrow(SkylineSplineMissileComp.AdditionalPoints[i].Location, SkylineSplineMissileComp.AdditionalPoints[i].Location + SkylineSplineMissileComp.AdditionalPoints[i].UpDirection * CoordSystemArrowLength, FLinearColor::Blue, CoordSystemArrowSize, CoordSystemArrowThickness);
			ClearHitProxy();
		}

		SetHitProxy(n"PinTransformHandle", EVisualizerCursor::GrabHand);
			if (SkylineSplineMissileComp.bPinTargetTransform)
				DrawWorldString("[Pinned]", SkylineSplineMissileComp.TargetWorldTransform.Location + FVector::UpVector * 200.0, FLinearColor::Green, 2.0, -1.0, false, true);
			else
				DrawWorldString("[Unpinned]", SkylineSplineMissileComp.TargetWorldTransform.Location + FVector::UpVector * 200.0, FLinearColor::Red, 2.0, -1.0, false, true);

			DrawWireBox(SkylineSplineMissileComp.TargetWorldTransform.Location + FVector::UpVector * 200.0, FVector::OneVector * 1.0, FQuat::Identity, FLinearColor::White, 50.0, true);
		ClearHitProxy();
	
		SkylineSplineMissileComp.UpdateSpline();
		DrawDebugSpline(SkylineSplineMissileComp);
	}

	UFUNCTION(BlueprintOverride)
	bool VisProxyHandleClick(FName HitProxy, FVector ClickOrigin, FVector ClickDirection, FKey Key, EInputEvent Event)
	{
		if(HitProxy == "TransformHandle")
		{
			bIsHandleSelected = true;
			return true;
		}

		if(HitProxy == "PinTransformHandle")
		{
			auto SkylineSplineMissileComp = Cast<USkylineSplineMissileComponent>(EditingComponent);
			SkylineSplineMissileComp.bPinTargetTransform = !SkylineSplineMissileComp.bPinTargetTransform;
			SkylineSplineMissileComp.PinnedTransform = SkylineSplineMissileComp.TargetWorldTransform;

			return true;
		}

		auto SkylineSplineMissileComp = Cast<USkylineSplineMissileComponent>(EditingComponent);
		for (int i = 0; i < SkylineSplineMissileComp.AdditionalPoints.Num() - 1; i++)
		{
			if(HitProxy == "AdditionalPoint_" + i)
			{

				return true;
			}
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void EndEditing()
	{
		bIsHandleSelected = false;
	}

	UFUNCTION(BlueprintOverride)
	bool GetWidgetLocation(FVector& OutLocation) const
	{
		if(!bIsHandleSelected)
			return false;

		auto SkylineSplineMissileComp = Cast<USkylineSplineMissileComponent>(EditingComponent);

		OutLocation = SkylineSplineMissileComp.TargetWorldTransform.Location;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool GetCustomInputCoordinateSystem(EVisualizerCoordinateSystem CoordSystem, EVisualizerWidgetMode WidgetMode, FTransform& OutTransform) const
	{
		if(!bIsHandleSelected)
			return false;

		if (CoordSystem != EVisualizerCoordinateSystem::Local)
			return false;

		auto SkylineSplineMissileComp = Cast<USkylineSplineMissileComponent>(EditingComponent);

		OutTransform = FTransform(SkylineSplineMissileComp.TargetWorldTransform.Rotation);

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool HandleInputDelta(FVector& DeltaTranslate, FRotator& DeltaRotate, FVector& DeltaScale)
	{
		if(!bIsHandleSelected)
			return false;

		auto SkylineSplineMissileComp = Cast<USkylineSplineMissileComponent>(EditingComponent);

		if (!DeltaTranslate.IsNearlyZero())
		{
			FVector LocalTranslation = SkylineSplineMissileComp.TargetWorldTransform.InverseTransformVectorNoScale(DeltaTranslate);
			SkylineSplineMissileComp.TargetTransform.Location = SkylineSplineMissileComp.TargetTransform.Location + SkylineSplineMissileComp.TargetTransform.TransformVectorNoScale(LocalTranslation);
		}

		if (!DeltaRotate.IsNearlyZero())
		{
			FRotator LocalRotation = SkylineSplineMissileComp.TargetWorldTransform.InverseTransformRotation(DeltaRotate.Inverse);
			SkylineSplineMissileComp.TargetTransform.Rotation = SkylineSplineMissileComp.WorldTransform.InverseTransformRotation(LocalRotation.Inverse).Quaternion();
		}

		if (!DeltaScale.IsNearlyZero())
		{
			SkylineSplineMissileComp.TargetTransform.Scale3D = SkylineSplineMissileComp.TargetTransform.Scale3D + DeltaScale;
		}

		return true;
	}

	void DrawDebugSpline(USkylineSplineMissileComponent SplineMissileComp)
	{
		FLinearColor Color = FLinearColor::Green;
		FLinearColor UpColor = FLinearColor::Blue;

		float Size = 5.0;
		float UpOffset = 50.0;

		int Resolution = 10;
		int Samples = int(SplineMissileComp.RuntimeSpline.Length / Resolution);

		TArray<FVector> Locations;
		TArray<FQuat> Rotations;
		SplineMissileComp.RuntimeSpline.GetLocations(Locations, Samples);
		SplineMissileComp.RuntimeSpline.GetQuats(Rotations, Samples);

		for (int i = 0; i < Samples - 1; i++)
		{
			DrawLine(Locations[i], Locations[i + 1], Color, Size);
			DrawLine(Locations[i] + Rotations[i].UpVector * UpOffset, Locations[i + 1] + Rotations[i + 1].UpVector * UpOffset, UpColor, Size);

			auto TransformOnSpline = FTransform(Rotations[i], Locations[i], FVector::OneVector);
			float SpinAlpha = (Math::Sin(i / float(Samples) * PI * 2.0 + (1.5 * PI)) + 1.0) * 0.5;
			FVector Offset = TransformOnSpline.TransformVectorNoScale((FVector::RightVector * SplineMissileComp.SpinRadius * SpinAlpha).RotateAngleAxis(SplineMissileComp.SpinAngle * (i / float(Samples)), FVector::ForwardVector));
			DrawPoint(Locations[i] + Offset, FLinearColor::Yellow, 10.0);
		}
	}
}

struct FSkylineSplineMissileData
{
	UPROPERTY()
	FVector Location;

	UPROPERTY()
	FVector UpDirection;

	UPROPERTY()
	float SpinRadius = -1.0;

	UPROPERTY()
	float Speed = 1000.0;
}

event void FSkylineSplineMissileComponentSignature();

class USkylineSplineMissileComponent : USceneComponent
{
	FHazeRuntimeSpline RuntimeSpline;

	TArray<FSkylineSplineMissileData> Point;

	FHazeAcceleratedFloat AccDistance;

	FTransform InitialRelativeTransform;

	UPROPERTY(EditAnywhere)
	float LaunchSpeed = 0.0;

	UPROPERTY(EditAnywhere)
	float TargetSpeed = 2000.0;

	UPROPERTY(EditAnywhere)
	float SpinRadius = 400.0;

	UPROPERTY(EditAnywhere)
	float SpinAngle = 360.0;

	UPROPERTY(EditAnywhere)
	float SpinRotationBlend = 1.0;

	UPROPERTY(EditAnywhere)
	FTransform TargetTransform;
	default TargetTransform.Location = FVector::ForwardVector * 500.0;

	FTransform InitialTransform;
	USceneComponent TargetComp;

	UPROPERTY(EditAnywhere)
	TArray<FSkylineSplineMissileData> AdditionalPoints;

	UPROPERTY(EditAnywhere)
	bool bPinTargetTransform = false;
	FTransform PinnedTransform;

	bool bLaunched = false;
	bool bImpacted = false;

	float DistanceAlpha = 0.0;

	UPROPERTY()
	FSkylineSplineMissileComponentSignature OnLaunch;

	UPROPERTY()
	FSkylineSplineMissileComponentSignature OnImpact;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		InitialTransform = WorldTransform;	
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InitialTransform = WorldTransform;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bLaunched || bImpacted)
			return;

/*
		AccDistance.ThrustTo(BIG_NUMBER, TargetSpeed, DeltaSeconds);
		SetDistance(AccDistance.Value);
*/
	}

	void MoveDistance(float Distance)
	{
		DistanceAlpha = (DistanceAlpha * RuntimeSpline.Length + Distance) / RuntimeSpline.Length;
		UpdatePosition();
	}

	void SetDistanceAlpha(float Alpha)
	{
		DistanceAlpha = Alpha;
		UpdatePosition();
	}

	void SetDistance(float Distance)
	{
		DistanceAlpha = GetSplineAlpha(Distance);
		UpdatePosition();
	}

	float GetSplineAlpha(float Distance)
	{
		return Math::Min(Distance, RuntimeSpline.Length) / RuntimeSpline.Length;
	}

	void UpdatePosition()
	{
		FVector StartLocation = WorldLocation;

		FVector Location;
		FQuat Rotation;
		RuntimeSpline.GetLocationAndQuat(DistanceAlpha, Location, Rotation);

		auto TransformOnSpline = FTransform(Rotation, Location, FVector::OneVector);
		float SpinAlpha = (Math::Sin(DistanceAlpha * PI * 2.0 + (1.5 * PI)) + 1.0) * 0.5;
		FVector Offset = TransformOnSpline.TransformVectorNoScale((FVector::RightVector * SpinRadius * SpinAlpha).RotateAngleAxis(SpinAngle * DistanceAlpha, FVector::ForwardVector));

		FVector ToSpline = (Location - StartLocation).SafeNormal;

		Location += Offset;

		FVector MovementDirection = (Location - StartLocation).SafeNormal;
		FQuat SpinRotation = FQuat::MakeFromXZ(MovementDirection, ToSpline); 

		Rotation = FQuat::Slerp(Rotation, SpinRotation, SpinRotationBlend);

		SetWorldLocationAndRotation(Location, Rotation);

		if (DistanceAlpha >= 1.0)
			Impact();
	}

	void Launch(USceneComponent TargetComponent)
	{
		InternalLaunch(TargetComponent = TargetComponent);
	}

	void Launch(FTransform ImpactTargetWorldTransform = FTransform::Identity)
	{
		InternalLaunch(ImpactTargetWorldTransform = ImpactTargetWorldTransform);
	}

	private void InternalLaunch(USceneComponent TargetComponent = nullptr, FTransform ImpactTargetWorldTransform = FTransform::Identity)
	{
		InitialTransform = WorldTransform;

		if (TargetComponent != nullptr)
		{
			TargetComp = TargetComponent;
		}

		if (!ImpactTargetWorldTransform.Equals(FTransform::Identity))
			TargetTransform = ImpactTargetWorldTransform.GetRelativeTransform(InitialTransform);

		UpdateSpline();

		bLaunched = true;		
		AccDistance.SnapTo(0.0, LaunchSpeed);
		OnLaunch.Broadcast();
		SetComponentTickEnabled(true);
	}

	void Impact()
	{
		bImpacted = true;
		OnImpact.Broadcast();
		SetComponentTickEnabled(false);
	}

	void UpdateSpline()
	{
		TArray<FVector> Points;
		TArray<FVector> UpDirections;

		Points.Add(InitialTransform.Location);

		for (auto AdditionalPoint : AdditionalPoints)
		{
			Points.Add(AdditionalPoint.Location);
			UpDirections.Add(AdditionalPoint.UpDirection);
		}

		Points.Add(TargetWorldTransform.Location);
		UpDirections.Add(InitialTransform.Rotation.UpVector);
		UpDirections.Add(TargetWorldTransform.Rotation.UpVector);

		RuntimeSpline.SetPointsAndUpDirections(Points, UpDirections);

		RuntimeSpline.SetCustomEnterTangentPoint(InitialTransform.Location - InitialTransform.Rotation.ForwardVector);
		RuntimeSpline.SetCustomExitTangentPoint(TargetWorldTransform.Location + TargetWorldTransform.Rotation.ForwardVector);
	}

	FTransform GetTargetWorldTransform() const property 
	{
		if (IsValid(TargetComp))
			return FTransform((TargetComp.WorldLocation - InitialTransform.Location).ToOrientationQuat(), TargetComp.WorldLocation);

		return TargetTransform * InitialTransform;
	}

	private FTransform LerpTransform(FTransform A, FTransform B, float Alpha) const
	{
		FVector Location = Math::Lerp(A.Location, B.Location, Alpha);
		FQuat Rotation = FQuat::Slerp(A.Rotation, B.Rotation, Alpha);
		FVector Scale3D = Math::Lerp(A.Scale3D, B.Scale3D, Alpha);
		return FTransform(Rotation, Location, Scale3D);
	}
};