UCLASS(NotBlueprintable)
class UGravityBikeFreeCircleJumpTriggerComponent : UGravityBikeFreeJumpTriggerComponent
{
	default Shape = FHazeShapeSettings::MakeSphere(500);

	UPROPERTY(EditAnywhere, Category = "Jump Trigger")
	float TowardsCenterAngleThreshold = 70;

	UPROPERTY(EditAnywhere, Category = "Jump Trigger")
	bool bNotActiveWhileInCenter = true;

	UPROPERTY(EditAnywhere, Category = "Jump Trigger", Meta = (EditCondition = "bNotActiveWhileInCenter"))
	float CenterRadius = 250;

	bool ShouldApplyBoost(const AGravityBikeFree GravityBike) const override
	{
		if(!Super::ShouldApplyBoost(GravityBike))
			return false;

		const FVector ToCenter = WorldLocation - GravityBike.ActorLocation;
		if(ToCenter.GetAngleDegreesTo(GravityBike.ActorVelocity) > TowardsCenterAngleThreshold)
			return false;

		if(bNotActiveWhileInCenter)
		{
			if(ToCenter.Size2D(UpVector) < CenterRadius)
				return false;
		}

		return true;
	}

	bool ShouldBlockJump(const AGravityBikeFree GravityBike) const override
	{
		if(!Super::ShouldBlockJump(GravityBike))
			return false;

		const FVector ToCenter = WorldLocation - GravityBike.ActorLocation;
		if(ToCenter.GetAngleDegreesTo(GravityBike.ActorVelocity) > TowardsCenterAngleThreshold)
			return false;

		if(bNotActiveWhileInCenter)
		{
			if(ToCenter.Size2D(UpVector) < CenterRadius)
				return false;
		}

		return true;
	}
};

class UGravityBikeFreeCircleJumpTriggerComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UGravityBikeFreeCircleJumpTriggerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto CircleJumpTriggerComp = Cast<UGravityBikeFreeCircleJumpTriggerComponent>(Component);
		if(CircleJumpTriggerComp == nullptr)
			return;

		if(CircleJumpTriggerComp.bNotActiveWhileInCenter)
		{
			DrawWireCylinder(CircleJumpTriggerComp.WorldLocation, CircleJumpTriggerComp.WorldRotation, FLinearColor::Red, CircleJumpTriggerComp.CenterRadius, 5000, 16);
		}
	}
};