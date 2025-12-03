namespace GravityBikeFree
{
	const FName AutoSteerTargetableCategory = n"GravityBikeFreeAutoSteer";
}

UCLASS(NotBlueprintable)
class UGravityBikeFreeAutoSteerTargetComponent : UTargetableComponent
{
	default TargetableCategory = GravityBikeFree::AutoSteerTargetableCategory;

	UPROPERTY(EditAnywhere, Meta = (ClampMin = "1.0"))
	float Radius = 5000;

	UPROPERTY(EditAnywhere, Meta = (ClampMin = "1.0"))
	float TargetAngle = 90;

	UPROPERTY(EditAnywhere, Meta = (ClampMin = "1.0"))
	float AutoSteerAngle = 130;

	UPROPERTY(EditAnywhere, Meta = (ClampMin = "1.0"))
	float ExtentsUp = 1000;

	UPROPERTY(EditAnywhere, Meta = (ClampMin = "1.0"))
	float ExtentsDown = 500;

	UPROPERTY(EditAnywhere)
	float ForwardOffset = 1000;

#if EDITOR
	UPROPERTY(EditInstanceOnly)
	FVector TestLocation = FVector::ZeroVector;
#endif

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		Targetable::ApplyTargetableRange(Query, Radius);

		if(!Query.Result.bPossibleTarget)
			return false;

		if(!IsPointWithinTrigger(Query.PlayerLocation))
			return false;

		const UGravityBikeFreeDriverComponent DriverComp = UGravityBikeFreeDriverComponent::Get(Query.Player);
		if(DriverComp == nullptr)
			return false;

		const AGravityBikeFree GravityBike = DriverComp.GetGravityBike();
		if(GravityBike == nullptr)
			return false;

		const FVector ToTarget = GetAutoSteerTargetLocation(GravityBike.ActorLocation) - GravityBike.ActorLocation;

		//Debug::DrawDebugDirectionArrow(GravityBike.ActorLocation, GravityBike.ActorVelocity.GetSafeNormal(), 500, 5, FLinearColor::Red);
		//Debug::DrawDebugDirectionArrow(GravityBike.ActorLocation, ToTarget, 500, 5, FLinearColor::Green);

		if(GravityBike.ActorVelocity.GetAngleDegreesTo(ToTarget) > (AutoSteerAngle / 2))
			return false;

		return true;
	}

	bool IsPointWithinTrigger(FVector Point) const
	{
		FVector RelativePoint = WorldTransform.InverseTransformPositionNoScale(Point);
		if(RelativePoint.Z > ExtentsUp || RelativePoint.Z < -ExtentsDown)
			return false;

		RelativePoint.Z = 0;
		if(RelativePoint.Size() > Radius)
			return false;

		if(RelativePoint.GetAngleDegreesTo(FVector::BackwardVector) > (TargetAngle / 2))
			return false;

		return true;
	}

	float GetAutoSteerInput(const AGravityBikeFree GravityBike) const
	{
		FVector ToAutoSteerTarget = GetAutoSteerTargetLocation(GravityBike.ActorLocation) - GravityBike.ActorLocation;
		ToAutoSteerTarget = ToAutoSteerTarget.VectorPlaneProject(GravityBike.MovementWorldUp).GetSafeNormal();

		ELeftRight Side = ToAutoSteerTarget.DotProduct(GravityBike.ActorRightVector) > 0 ? ELeftRight::Right : ELeftRight::Left;

		float AutoSteering = 0;
		if(Side == ELeftRight::Right)
			AutoSteering = 1.0;
		else
			AutoSteering = -1.0;

		float TurnAmount = Math::Saturate(ToAutoSteerTarget.GetAngleDegreesTo(GravityBike.ActorForwardVector.VectorPlaneProject(GravityBike.MovementWorldUp)) / 20);

		return AutoSteering * TurnAmount;
	}

	FVector GetAutoSteerTargetLocation(FVector PlayerLocation) const
	{
		return WorldTransform.TransformPositionNoScale(FVector::ForwardVector * ForwardOffset);
	}
};

#if EDITOR
class UGravityBikeFreeAutoSteerTargetComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UGravityBikeFreeAutoSteerTargetComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto AutoSteerComp = Cast<UGravityBikeFreeAutoSteerTargetComponent>(Component);
		if(AutoSteerComp == nullptr)
			return;

		DrawArrow(AutoSteerComp.WorldLocation, AutoSteerComp.WorldLocation + AutoSteerComp.ForwardVector * 1000, FLinearColor::Red, 100, 20);
		DrawArc(AutoSteerComp.WorldLocation, AutoSteerComp.TargetAngle, AutoSteerComp.Radius, -AutoSteerComp.ForwardVector, FLinearColor::Red, 10, AutoSteerComp.UpVector);
		DrawArc(AutoSteerComp.WorldLocation + AutoSteerComp.UpVector * AutoSteerComp.ExtentsUp, AutoSteerComp.TargetAngle, AutoSteerComp.Radius, -AutoSteerComp.ForwardVector, FLinearColor::Red, 10, AutoSteerComp.UpVector);
		DrawArc(AutoSteerComp.WorldLocation - AutoSteerComp.UpVector * AutoSteerComp.ExtentsDown, AutoSteerComp.TargetAngle, AutoSteerComp.Radius, -AutoSteerComp.ForwardVector, FLinearColor::Red, 10, AutoSteerComp.UpVector);
		
		DrawArc(AutoSteerComp.WorldLocation, AutoSteerComp.AutoSteerAngle, AutoSteerComp.Radius, AutoSteerComp.ForwardVector, FLinearColor::Yellow, 10, AutoSteerComp.UpVector);
	
		FVector TestLocation = AutoSteerComp.WorldTransform.TransformPositionNoScale(AutoSteerComp.TestLocation);
		if(AutoSteerComp.IsPointWithinTrigger(TestLocation))
			DrawPoint(TestLocation, FLinearColor::Green, 10);
		else
			DrawPoint(TestLocation, FLinearColor::Red, 10);

		DrawPoint(AutoSteerComp.GetAutoSteerTargetLocation(TestLocation), FLinearColor::Yellow, 50);
	}
};
#endif