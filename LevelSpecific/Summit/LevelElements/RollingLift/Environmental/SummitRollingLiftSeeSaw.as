struct FSummitRollingLiftSeeSawData
{
	FVector ImpactLocation;
	ASummitRollingLift RollingLift;	
}

class USummitRollingLiftSeeSawRootComponent : USceneComponent
{

}

class ASummitRollingLiftSeeSaw : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USummitRollingLiftSeeSawRootComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent AxisRotateComp;

	/** How much force gets added downwards if the seesaw is touching a rolling lift */ 
	UPROPERTY(EditAnywhere, Category = "Settings")
	float RollingLiftWeight = 200.0;	

	UPROPERTY(EditAnywhere, Category = "Settings")
	float SeeSawRadius = 4000.0;

	TOptional<FSummitRollingLiftSeeSawData> CurrentImpactingData;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(CurrentImpactingData.IsSet())
		{
			FVector ImpactLocation = CurrentImpactingData.Value.ImpactLocation;
			auto RollingLift = CurrentImpactingData.Value.RollingLift;

			FVector PivotToLift = RollingLift.ActorLocation - AxisRotateComp.WorldLocation;
			float DistanceOnForwardAxis = PivotToLift.DotProduct(AxisRotateComp.ForwardVector);
			DistanceOnForwardAxis = Math::Abs(DistanceOnForwardAxis);
			float PercentDistance = DistanceOnForwardAxis / SeeSawRadius;

			FVector Force = RollingLift.GetGravityDirection() * RollingLiftWeight * PercentDistance;
			FauxPhysics::ApplyFauxForceToActorAt(this, ImpactLocation, Force);
		}
	}

	void GetPunched(AActor Smashapult, FVector Impulse)
	{
		FauxPhysics::ApplyFauxImpulseToActorAt(this, Smashapult.ActorLocation, Impulse);
	}
};
#if EDITOR
class USummitRollingLiftSeeSawComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USummitRollingLiftSeeSawRootComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Comp = Cast<USummitRollingLiftSeeSawRootComponent>(Component);
		if(!ensure((Comp != nullptr) && (Comp.Owner != nullptr)))
			return;

		auto SeeSaw = Cast<ASummitRollingLiftSeeSaw>(Comp.Owner);
		if(SeeSaw == nullptr)
			return;
		
		const FVector Start = SeeSaw.AxisRotateComp.WorldLocation;
		DrawArrow(Start, Start + SeeSaw.AxisRotateComp.ForwardVector * SeeSaw.SeeSawRadius, FLinearColor::Red, 80, 40, false);
		DrawArrow(Start, Start - SeeSaw.AxisRotateComp.ForwardVector * SeeSaw.SeeSawRadius, FLinearColor::Red, 80, 40, false);
	}
}
#endif