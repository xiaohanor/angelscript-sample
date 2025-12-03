struct FGravityBikeWeaponChargeSplineUser
{
	AGravityBikeFree GravityBike;
	UGravityBikeWeaponUserComponent WeaponUserComp;
	UNiagaraComponent NiagaraComp;
}

class AGravityBikeWeaponChargeSpline : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeSplineComponent Spline;
	default Spline.EditingSettings.bEnableVisualizeScale = true;
	default Spline.EditingSettings.VisualizeScale = 100.0;

	UPROPERTY(DefaultComponent)
	UBoxComponent Trigger;

	TArray<FGravityBikeWeaponChargeSplineUser> ChargeUsers;
//	TMap<AGravityBikeFree, UGravityBikeWeaponUserComponent> GravityBikes;

	UPROPERTY(EditAnywhere)
	float BaseWidth = 100.0;

	UPROPERTY(EditAnywhere)
	float MaxChargeSpeed = 5000.0;

	UPROPERTY(EditAnywhere)
	float ChargeRate = 0.25;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem ChargeVFX;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Find the widest part of the spline
		float MaxScale = 0.0;
		for (auto SplinePoint : Spline.SplinePoints)
		{
			float SplinePointMaxScale = Math::Max(SplinePoint.RelativeScale3D.Y, SplinePoint.RelativeScale3D.Z);
			if (SplinePointMaxScale > MaxScale)
				MaxScale = SplinePointMaxScale;
		}

		// Add margin to trigger based on widest part
		Spline.PositionBoxComponentToContainEntireSpline(Trigger, MaxScale * BaseWidth);
	
		Trigger.OnComponentBeginOverlap.AddUFunction(this, n"HandleBeginOverlap");
		Trigger.OnComponentEndOverlap.AddUFunction(this, n"HandleEndOverlap");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
//		DrawDebug();

		for (auto ChargeUser : ChargeUsers)
		{
			if (!IsInsideVolume(ChargeUser.GravityBike.ActorLocation, 0.0))
			{
				ChargeUser.NiagaraComp.SetVisibility(false);
				continue;
			}

			ChargeUser.NiagaraComp.SetVisibility(true);

			float GravityBikeSpeed = ChargeUser.GravityBike.ActorVelocity.Size();
			PrintToScreen("Speed: " + GravityBikeSpeed, 0.0);

			float ChargeAlpha = Math::Min(1.0, GravityBikeSpeed / MaxChargeSpeed);
			ChargeUser.NiagaraComp.RelativeScale3D = FVector::OneVector * ChargeAlpha * 2.5;

			ChargeAlpha = Math::Pow(ChargeAlpha, 4.0);
	
			ChargeUser.WeaponUserComp.AddCharge(ChargeRate * ChargeAlpha * DeltaSeconds);
		}

/*
		for (auto GravityBike : GravityBikes)
		{
			if (!IsInsideVolume(GravityBike.Key.ActorLocation, 0.0))
				continue;

			float GravityBikeSpeed = GravityBike.Key.ActorVelocity.Size();
			PrintToScreen("Speed: " + GravityBikeSpeed, 0.0);

			float ChargeAlpha = Math::Min(1.0, GravityBikeSpeed / MinChargeSpeed);

			ChargeAlpha *= ChargeAlpha;
	
			GravityBike.Value.AddCharge(1.0 * ChargeAlpha * DeltaSeconds);
		}
*/
	}

	UFUNCTION()
	private void HandleBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		auto GravityBike = Cast<AGravityBikeFree>(OtherActor);
		if (GravityBike == nullptr)
			return;

		auto WeaponUserComp = UGravityBikeWeaponUserComponent::Get(GravityBike.GetDriver());

		FGravityBikeWeaponChargeSplineUser ChargeUser;
		ChargeUser.GravityBike = GravityBike;
		ChargeUser.WeaponUserComp = WeaponUserComp;
		ChargeUser.NiagaraComp = Niagara::SpawnLoopingNiagaraSystemAttached(ChargeVFX, GravityBike.RootComponent);

		if (ChargeUsers.IsEmpty())
			SetActorTickEnabled(true);

		ChargeUsers.Add(ChargeUser);
/*
		if (GravityBikes.IsEmpty())
			SetActorTickEnabled(true);

		GravityBikes.Add(GravityBike, WeaponUserComp);
*/
	}

	UFUNCTION()
	private void HandleEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		auto GravityBike = Cast<AGravityBikeFree>(OtherActor);
		if (GravityBike == nullptr)
			return;

		for (int i = ChargeUsers.Num() - 1; i >= 0; i--)
		{
			if (ChargeUsers[i].GravityBike == GravityBike)
			{
				ChargeUsers[i].NiagaraComp.DestroyComponent(GravityBike);
				ChargeUsers.RemoveAt(i);
			}
		}

		if (ChargeUsers.IsEmpty())
			SetActorTickEnabled(false);

/*
		GravityBikes.Remove(GravityBike);

		if (GravityBikes.IsEmpty())
			SetActorTickEnabled(false);
*/
	}

	FVector GetSplineRelativeLocation(FVector WorldLocation)
	{
		float SplineDistance = Spline.GetClosestSplineDistanceToWorldLocation(WorldLocation);
		FTransform Transform = Spline.GetWorldTransformAtSplineDistance(SplineDistance);

		FVector Location = Transform.InverseTransformPositionNoScale(WorldLocation);
		Location.X = SplineDistance;

		return Location;
	}

	bool IsInsideVolume(FVector WorldLocation, float Radius = 0.0)
	{
		FVector Location = GetSplineRelativeLocation(WorldLocation);
		FTransform TransformAtLocation = Spline.GetWorldTransformAtSplineDistance(Location.X);

		if (Location.X < Spline.SplineLength - Radius && Location.X > 0.0 + Radius)
			if (Math::Abs(Location.Y) < TransformAtLocation.Scale3D.Y * BaseWidth - Radius)
				if (Math::Abs(Location.Z) < TransformAtLocation.Scale3D.Z * BaseWidth - Radius)
					return true;

		return false;
	}

	void DrawDebug()
	{
		FTransform FrontTransform = Spline.GetWorldTransformAtSplineDistance(Spline.SplineLength);
		FTransform BackTransform = Spline.GetWorldTransformAtSplineDistance(0.0);

		FVector TL = FVector(0.0, -1.0, 1.0) * BaseWidth;
		FVector TR = FVector(0.0, 1.0, 1.0) * BaseWidth;
		FVector BL = FVector(0.0, -1.0, -1.0) * BaseWidth;
		FVector BR = FVector(0.0, 1.0, -1.0) * BaseWidth;

		Debug::DrawDebugLine(BackTransform.TransformPosition(TL), BackTransform.TransformPosition(TR), FLinearColor::Red, 5.0, 0.0);
		Debug::DrawDebugLine(BackTransform.TransformPosition(BL), BackTransform.TransformPosition(BR), FLinearColor::Red, 5.0, 0.0);
		Debug::DrawDebugLine(FrontTransform.TransformPosition(TL), FrontTransform.TransformPosition(TR), FLinearColor::Red, 5.0, 0.0);
		Debug::DrawDebugLine(FrontTransform.TransformPosition(BL), FrontTransform.TransformPosition(BR), FLinearColor::Red, 5.0, 0.0);

		Debug::DrawDebugLine(BackTransform.TransformPosition(TL), BackTransform.TransformPosition(BL), FLinearColor::Red, 5.0, 0.0);
		Debug::DrawDebugLine(BackTransform.TransformPosition(TR), BackTransform.TransformPosition(BR), FLinearColor::Red, 5.0, 0.0);
		Debug::DrawDebugLine(FrontTransform.TransformPosition(TL), FrontTransform.TransformPosition(BL), FLinearColor::Red, 5.0, 0.0);
		Debug::DrawDebugLine(FrontTransform.TransformPosition(TR), FrontTransform.TransformPosition(BR), FLinearColor::Red, 5.0, 0.0);

		float LineLength = Spline.SplineLength;
		float LineStart = 0.0;

		DrawDebugSplineLine(TL, LineStart, LineLength);
		DrawDebugSplineLine(TR, LineStart, LineLength);
		DrawDebugSplineLine(BL, LineStart, LineLength);
		DrawDebugSplineLine(BR, LineStart, LineLength);
	}

	void DrawDebugSplineLine(FVector Offset, float LineStartDistance, float LineLength)
	{
		float SegmentLenght = 50.0;
		int Segments = Math::FloorToInt(LineLength / SegmentLenght);
		SegmentLenght = LineLength / Segments;

		for (int i = 0; i < Segments; i++)
		{
			FVector LineStart;
			FVector LineEnd;

			LineStart = Spline.GetWorldTransformAtSplineDistance(LineStartDistance + i * SegmentLenght).TransformPosition(Offset);
			LineEnd = Spline.GetWorldTransformAtSplineDistance(LineStartDistance + (i + 1) * SegmentLenght).TransformPosition(Offset);
			Debug::DrawDebugLine(LineStart, LineEnd, FLinearColor::Red, 5.0, 0.0);
		}
	}
};