UCLASS(NotBlueprintable)
class UGravityBikeFreeRampJumpTriggerComponent : UGravityBikeFreeJumpTriggerComponent
{
	default Shape = FHazeShapeSettings::MakeBox(FVector(500, 500, 500));

	UPROPERTY(EditAnywhere, Category = "Jump Trigger|Boost", Meta = (EditCondition = "bApplyBoost", ClampMin = "1", ClampMax = "179"))
	float ApplyBoostAngleThreshold = 90;

	UPROPERTY(EditAnywhere, Category = "Jump Trigger|Jump", Meta = (EditCondition = "bBlockJump", ClampMin = "1", ClampMax = "179"))
	float BlockJumpAngleThreshold = 90;

	bool ShouldApplyBoost(const AGravityBikeFree GravityBike) const override
	{
		if(!Super::ShouldApplyBoost(GravityBike))
			return false;

		if(GravityBike.ActorVelocity.GetAngleDegreesTo(ForwardVector) > ApplyBoostAngleThreshold)
			return false;

		return true;
	}

	bool ShouldBlockJump(const AGravityBikeFree GravityBike) const override
	{
		if(GravityBike.ActorVelocity.GetAngleDegreesTo(ForwardVector) > BlockJumpAngleThreshold)
			return false;

		return true;
	}
};

class UGravityBikeFreeRampJumpTriggerComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UGravityBikeFreeRampJumpTriggerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto RampComp = Cast<UGravityBikeFreeRampJumpTriggerComponent>(Component);
		if(RampComp == nullptr)
			return;

		DrawArrow(RampComp.WorldLocation, RampComp.WorldLocation + RampComp.ForwardVector * 1000, FLinearColor::Red, 100, 3, true);

		if(RampComp.bApplyBoost)
			DrawCone(RampComp.WorldLocation, RampComp.ForwardVector, 500, RampComp.ApplyBoostAngleThreshold, FLinearColor::Yellow);

		if(RampComp.bBlockJump)
			DrawCone(RampComp.WorldLocation, RampComp.ForwardVector, 750, RampComp.BlockJumpAngleThreshold, FLinearColor::Red);
	}

	void DrawCone(FVector Origin, FVector Direction, float Radius, float ConeAngle, FLinearColor Color) const
	{
		float ConeRadians = Math::DegreesToRadians(ConeAngle);

		// Construct perpendicular vector
		FVector P1 = Direction.CrossProduct(Direction.GetAbs().Equals(FVector::UpVector) ? FVector::RightVector : FVector::UpVector);
		P1.Normalize();

		FVector P2 = P1.CrossProduct(Direction);

		// Draw cone sides
		FVector Tip = Direction * Radius;
		FVector TiltedTip = FQuat(P1, ConeRadians) * Tip;
		FVector ConeBase = Direction * Math::Cos(ConeRadians) * Radius;

		float StepRadians = TWO_PI / 10;

		for(int i = 0; i < 10; ++i)
		{
			float Angle = i * StepRadians;
			FVector StepTip = FQuat(Direction, Angle) * TiltedTip;

			DrawDashedLine(Origin, Origin + StepTip, FLinearColor::Gray);
		}

		// Draw tip circle
		DrawCircle(Origin + ConeBase, Math::Sin(ConeRadians) * Radius, Color, 2.0, Direction);

		// Draw rotational arcs
		DrawArc(Origin, ConeAngle * 2.0, Radius, Direction, Color, 2.0, P1, bDrawSides = false);
		DrawArc(Origin, ConeAngle * 2.0, Radius, Direction, Color, 2.0, P2, bDrawSides = false);
	}
};