struct FTundraFairyPerchSplineSwitchableSplineData
{
	float DistanceOfConnection;
	FVector InitialForward;
}

class UTundraFairyPerchSplineSwitchableComponent : UActorComponent
{
	UPROPERTY(EditInstanceOnly)
	TArray<APerchSpline> ConnectedPerchSplines;

	UPROPERTY(EditInstanceOnly)
	bool bIsMainSpline = true;

	APerchSpline OwnerPerchSpline;
	TArray<FTundraFairyPerchSplineSwitchableSplineData> ConnectedPerchSplinesData;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OwnerPerchSpline = Cast<APerchSpline>(Owner);
		devCheck(OwnerPerchSpline != nullptr, "UFairyPerchSplineSwitchableComponent is placed on an actor that isn't a perch spline, this is not supported!");

		for(int i = 0; i < ConnectedPerchSplines.Num(); i++)
		{
			if(bIsMainSpline)
			{
				FTundraFairyPerchSplineSwitchableSplineData NewData;
				FTransform ConnectedSplineStartPoint = ConnectedPerchSplines[i].Spline.GetWorldTransformAtSplineDistance(0.0);
				FTransform ConnectedSplineEndPoint = ConnectedPerchSplines[i].Spline.GetWorldTransformAtSplineDistance(ConnectedPerchSplines[i].Spline.SplineLength);

				FSplinePosition ClosestPosToConnectedStartPoint = OwnerPerchSpline.Spline.GetClosestSplinePositionToWorldLocation(ConnectedSplineStartPoint.Location);
				FSplinePosition ClosestPosToConnectedEndPoint = OwnerPerchSpline.Spline.GetClosestSplinePositionToWorldLocation(ConnectedSplineEndPoint.Location);
				if(ClosestPosToConnectedStartPoint.WorldLocation.DistSquared(ConnectedSplineStartPoint.Location) < ClosestPosToConnectedEndPoint.WorldLocation.DistSquared(ConnectedSplineEndPoint.Location))
				{
					NewData.DistanceOfConnection = ClosestPosToConnectedStartPoint.CurrentSplineDistance;
					NewData.InitialForward = ConnectedSplineStartPoint.Rotation.ForwardVector;
				}
				else
				{
					NewData.DistanceOfConnection = ClosestPosToConnectedEndPoint.CurrentSplineDistance;
					NewData.InitialForward = -ConnectedSplineEndPoint.Rotation.ForwardVector;
				}
				ConnectedPerchSplinesData.Add(NewData);
			}
			else
			{
				FTundraFairyPerchSplineSwitchableSplineData NewData;
				FTransform CurrentSplineStartPoint = OwnerPerchSpline.Spline.GetWorldTransformAtSplineDistance(0.0);
				FTransform CurrentSplineEndPoint = OwnerPerchSpline.Spline.GetWorldTransformAtSplineDistance(OwnerPerchSpline.Spline.SplineLength);

				FTransform ClosestTfToCurrentStartPoint = ConnectedPerchSplines[i].Spline.GetClosestSplineWorldTransformToWorldLocation(CurrentSplineStartPoint.Location);
				FTransform ClosestTfToCurrentEndPoint = ConnectedPerchSplines[i].Spline.GetClosestSplineWorldTransformToWorldLocation(CurrentSplineEndPoint.Location);
				if(ClosestTfToCurrentStartPoint.Location.DistSquared(CurrentSplineStartPoint.Location) < ClosestTfToCurrentEndPoint.Location.DistSquared(CurrentSplineEndPoint.Location))
				{
					NewData.DistanceOfConnection = 0.0;
					NewData.InitialForward = ClosestTfToCurrentStartPoint.Rotation.ForwardVector;
				}
				else
				{
					NewData.DistanceOfConnection = OwnerPerchSpline.Spline.SplineLength;
					NewData.InitialForward = ClosestTfToCurrentEndPoint.Rotation.ForwardVector;
				}
				ConnectedPerchSplinesData.Add(NewData);
			}

			auto SwitchableComponent = UTundraFairyPerchSplineSwitchableComponent::Get(ConnectedPerchSplines[i]);
			if(SwitchableComponent != nullptr)
				continue;

			SwitchableComponent = UTundraFairyPerchSplineSwitchableComponent::Create(ConnectedPerchSplines[i]);
			SwitchableComponent.bIsMainSpline = false;
			if(!SwitchableComponent.ConnectedPerchSplines.Contains(OwnerPerchSpline))
				SwitchableComponent.ConnectedPerchSplines.Add(OwnerPerchSpline);
		}
	}
}