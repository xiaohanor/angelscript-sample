class UTundraWindCurrentVisualizationComponent : UActorComponent
{
	default bIsEditorOnly = true;
}

class UTundraWindCurrentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UTundraWindCurrentVisualizationComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Spline = UHazeSplineComponent::Get(Component.Owner);
		auto Actor = Cast<ATundraWindCurrentSpline>(Component.Owner);

		for(int i = 0; i < Spline.SplinePoints.Num() - 1; i++)
		{
			FVector Point1 = Spline.WorldTransform.TransformPosition(Spline.SplinePoints[i].RelativeLocation);
			FVector Point2 = Spline.WorldTransform.TransformPosition(Spline.SplinePoints[i + 1].RelativeLocation);
			FVector OneToTwo = Point2 - Point1;

			FVector Origin = Point1 + OneToTwo * 0.5;
			DrawWireCylinder(Origin, FRotator::MakeFromZ(OneToTwo.GetSafeNormal()), FLinearColor::White, Actor.WindCurrentRadius, OneToTwo.Size() * 0.5, 8);
		}

		FVector ArrowOrigin = Spline.WorldTransform.TransformPosition(Spline.SplinePoints[!Actor.bFlipWindDirection ? 0 : Spline.SplinePoints.Num() - 1].RelativeLocation);
		FVector ArrowDirection = (Spline.WorldTransform.TransformPosition(Spline.SplinePoints[!Actor.bFlipWindDirection ? 1 : Spline.SplinePoints.Num() - 2].RelativeLocation) - ArrowOrigin).GetSafeNormal();
		DrawArrow(ArrowOrigin, ArrowOrigin + ArrowDirection * 100, FLinearColor::Red, 15, 3);
	}
}

UCLASS(Abstract)
class ATundraWindCurrentSpline : ASplineActor
{
	UPROPERTY(DefaultComponent)
	UTundraWindCurrentVisualizationComponent VisualizationComponent;

	/* The radius of the wind tunnel */
	UPROPERTY(EditAnywhere)
	float WindCurrentRadius = 50.0;

	/* How fast the player will travel in the wind current */
	UPROPERTY(EditAnywhere)
	float TargetSpeed = 3000;

	/* This acceleration will be applied every frame * deltaTime. So if Acceleration == TargetSpeed, TargetSpeed will be reached in 1 second */
	UPROPERTY(EditAnywhere)
	float Acceleration = 9000;

	/* This is the max speed the player will move at when inside the wind current. When in the center (at the spline), the max speed will be used, it will linearly fall off as the player gets closer to the wind current edge */
	UPROPERTY(EditAnywhere)
	float SteeringMaxSpeed = 0;

	/* This multiplier will be multiplied with the velocity from the player to the center of the wind current. This is fine to increase really high since you can never overshoot center */
	UPROPERTY(EditAnywhere)
	float CorrectionalSpeedMultiplier = 5.0;

	/* Whether the wind should instead go the other direction on the spline */
	UPROPERTY(EditAnywhere)
	bool bFlipWindDirection = false;

	/* If true, will draw cylinders around splines so you can see where they are */
	UPROPERTY(EditAnywhere)
	bool bDebugDraw = true;

	UPROPERTY(EditAnywhere)
	private bool bWindCurrentActive = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(bWindCurrentActive)
		{
			auto ContainerComponent = UTundraWindCurrentSplineContainer::GetOrCreate(Game::Zoe);
			ContainerComponent.WindCurrents.AddUnique(this);
		}
		else
		{
			OnDeactivateWindCurrent();
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bDebugDraw && bWindCurrentActive)
			DebugDraw();
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		auto ContainerComponent = UTundraWindCurrentSplineContainer::GetOrCreate(Game::Zoe);
		ContainerComponent.WindCurrents.RemoveSingleSwap(this);
	}

	bool IsLocationInWindCurrent(FVector Location)
	{
		FVector ClosestPoint;
		float SplineDistance;

		return IsLocationInWindCurrent(Location, ClosestPoint, SplineDistance);
	}

	bool IsLocationInWindCurrent(FVector Location, FVector&out ClosestPoint, float&out SplineDistance)
	{
		SplineDistance = Spline.GetClosestSplineDistanceToWorldLocation(Location);
		ClosestPoint = Spline.GetWorldLocationAtSplineDistance(SplineDistance);

		return ClosestPoint.DistSquared(Location) < Math::Square(WindCurrentRadius);
	}

	void DebugDraw()
	{
		for(int i = 0; i < Spline.SplinePoints.Num() - 1; i++)
		{
			FVector Point1 = Spline.WorldTransform.TransformPosition(Spline.SplinePoints[i].RelativeLocation);
			FVector Point2 = Spline.WorldTransform.TransformPosition(Spline.SplinePoints[i + 1].RelativeLocation);
			FVector OneToTwo = Point2 - Point1;

			FVector Origin = Point1 + OneToTwo * 0.5;
			Debug::DrawDebugCylinder(Origin, FRotator::MakeFromZ(OneToTwo.GetSafeNormal()), WindCurrentRadius, OneToTwo.Size() * 0.5, FLinearColor::White);
		}

		FVector ArrowOrigin = Spline.WorldTransform.TransformPosition(Spline.SplinePoints[!bFlipWindDirection ? 0 : Spline.SplinePoints.Num() - 1].RelativeLocation);
		FVector ArrowDirection = (Spline.WorldTransform.TransformPosition(Spline.SplinePoints[!bFlipWindDirection ? 1 : Spline.SplinePoints.Num() - 2].RelativeLocation) - ArrowOrigin).GetSafeNormal();
		Debug::DrawDebugArrow(ArrowOrigin, ArrowOrigin + ArrowDirection * 100, 100, FLinearColor::Red, 3);
	}

	UFUNCTION()
	void ActivateWindCurrent()
	{
		if(bWindCurrentActive)
			return;

		bWindCurrentActive = true;
		auto ContainerComponent = UTundraWindCurrentSplineContainer::GetOrCreate(Game::Zoe);
		ContainerComponent.WindCurrents.AddUnique(this);

		OnActivateWindCurrent();
	}

	UFUNCTION()
	void DeactivateWindCurrent()
	{
		if(!bWindCurrentActive)
			return;

		bWindCurrentActive = false;
		auto ContainerComponent = UTundraWindCurrentSplineContainer::GetOrCreate(Game::Zoe);
		ContainerComponent.WindCurrents.RemoveSingleSwap(this);

		OnDeactivateWindCurrent();
	}

	UFUNCTION(BlueprintEvent)
	void OnActivateWindCurrent()
	{
	}

	UFUNCTION(BlueprintEvent)
	void OnDeactivateWindCurrent()
	{
	}
}

class UTundraWindCurrentSplineContainer : UActorComponent
{
	TArray<ATundraWindCurrentSpline> WindCurrents;
}