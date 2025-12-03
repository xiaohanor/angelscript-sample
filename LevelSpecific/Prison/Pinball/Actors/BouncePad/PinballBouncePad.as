struct FPinballBouncePadHitResult
{
	float Impulse;
	FVector Direction;
	FVector LaunchLocation;
	FPinballPaddleAutoAimTargetData AutoAimTargetData;

	FVector GetImpulseVector() const
	{
		return Direction * Impulse;
	}
};

UCLASS(Abstract)
class APinballBouncePad : AHazeActor
{
	access Internal = private, UPinballBouncePadVisualizer;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent CollisionMeshComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent VisualRoot;

	UPROPERTY(DefaultComponent, Attach = VisualRoot)
	UStaticMeshComponent VisualMeshComp;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UPinballLauncherComponent LauncherComp;
	default LauncherComp.bAllowLaunchFromBallSide = true;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UPinballBouncePadVisualizeComponent VisualizeComp;
#endif

	UPROPERTY(EditAnywhere, Category = "Bounce Pad", Meta = (ClampMin = "0.0"))
	protected float Impulse = 5000;

	UPROPERTY(EditInstanceOnly, Category = "Bounce Pad")
	TArray<FPinballPaddleAutoAimTargetData> AutoAimTargets;

	UPROPERTY(EditAnywhere, Category = "Bounce Pad")
	float VerticalOffset = -50;

	UPROPERTY(EditAnywhere, Category = "Bounce Pad")
	float Radius = 200;

	UPROPERTY(EditAnywhere, Category = "Bounce Pad")
	FVector RelativeLaunchLocation = FVector(0, 0, 50);

	UPROPERTY(EditAnywhere, Category = "Bounce Pad|Aim At Location")
	bool bAlwaysAimAtLocation = false;

	UPROPERTY(EditAnywhere, Category = "Bounce Pad|Aim At Location", Meta = (EditCondition = "bAlwaysAimAtLocation", EditConditionHides))
	FVector2D AimAtLocation = FVector2D(0, 100);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Pinball::GetPaddlePlayer());
		
		LauncherComp.OnHitByBall.AddUFunction(this, n"OnHitByBall");
	}

	UFUNCTION()
	private void OnHitByBall(UPinballBallComponent BallComp, bool bIsProxy)
	{
		FPinballBouncePadOnHitByBallEventData EventData;
		EventData.BallComp = BallComp;
		EventData.bIsProxy = bIsProxy;
		UPinballBouncePadEventHandler::Trigger_OnHitByBall(this, EventData);
	}

	bool CalculateBouncePadHitResult(FPinballBouncePadHitResult&out OutHitResult) const
	{
		const FVector LaunchLocation = GetLaunchLocation();

		FVector ImpactNormal;
		if(GetBouncePadNormal(ImpactNormal))
		{
			FPinballPaddleAutoAimTargetData AutoAimTargetData;
			if(Pinball::FindAutoAim(LaunchLocation, ImpactNormal, AutoAimTargets, AutoAimTargetData))
			{
				OutHitResult.AutoAimTargetData = AutoAimTargetData;
				OutHitResult.Direction = AutoAimTargetData.GetDirectionToAutoAimFrom(GetLaunchLocation()).VectorPlaneProject(FVector::ForwardVector).GetSafeNormal();

				if(AutoAimTargetData.bOverrideImpulse)
					OutHitResult.Impulse = AutoAimTargetData.Impulse;
				else
					OutHitResult.Impulse = Impulse;
			}
			else
			{
				OutHitResult.Direction = ActorUpVector.VectorPlaneProject(FVector::ForwardVector).GetSafeNormal();
				OutHitResult.Impulse = Impulse;
			}

			OutHitResult.LaunchLocation = LaunchLocation;

			return true;
		}
		else
		{
			return false;
		}
	}

	access:Internal
	bool GetBouncePadNormal(FVector&out OutImpactNormal) const
	{
		// FVector RelativeImpactLocation = ActorTransform.InverseTransformPosition(ImpactLocation);
		// RelativeImpactLocation.Z = 0;
		// if(RelativeImpactLocation.SizeSquared() > Math::Square(Radius))
		// 	return false;	// Impact was on sides

		// FPlane TopPlane = FPlane(ActorLocation + (ActorUpVector * VerticalOffset), ActorUpVector);
		// if(TopPlane.PlaneDot(PlayerLocation) < 0)
		// 	return false;	// Player was behind top of bounce pad

		if(bAlwaysAimAtLocation)
		{
			const FVector DirToAimAtLocation = (GetAimAtLocationWorld() - GetLaunchLocation());
			OutImpactNormal = DirToAimAtLocation;
		}
		else
		{
			OutImpactNormal = ActorUpVector;
		}

		OutImpactNormal.X = 0;
		OutImpactNormal.Normalize();

		return true;
	}

	access:Internal
	FVector GetLaunchLocation() const
	{
		return ActorTransform.TransformPositionNoScale(FVector(0, RelativeLaunchLocation.Y, RelativeLaunchLocation.Z));
	}

	access:Internal
	FVector GetAimAtLocationWorld() const
	{
		return ActorTransform.TransformPositionNoScale(FVector(0, AimAtLocation.X, AimAtLocation.Y));
	}
};

#if EDITOR
UCLASS(NotBlueprintable, NotPlaceable, HideCategories = "Debug ComponentTick Activation Cooking Disable Tags Navigation")
class UPinballBouncePadVisualizeComponent : UActorComponent
{
	UPROPERTY(EditInstanceOnly, Category = "Simulation")
	bool bSimulateHit = true;

	UPROPERTY(EditInstanceOnly, Category = "Simulation", Meta = (UIMin = "-1.0", UIMax = "1.0", EditCondition = "bSimulateHit", EditConditionHides))
	float SimulatedInput = 0;

	UPROPERTY(EditInstanceOnly, Category = "Simulation", Meta = (EditCondition = "bSimulateHit", EditConditionHides))
	float SimulationDuration = 1;
};

class UPinballBouncePadVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UPinballBouncePadVisualizeComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(UActorComponent Component)
	{
		auto VisualizeComp = Cast<UPinballBouncePadVisualizeComponent>(Component);
		auto BouncePad = Cast<APinballBouncePad>(Component.Owner);

		Pinball::DrawAutoAims(this, BouncePad.ActorLocation, BouncePad.AutoAimTargets);

		DrawCircle(BouncePad.ActorLocation + (BouncePad.ActorUpVector * BouncePad.VerticalOffset), BouncePad.Radius, FLinearColor::LucBlue, 3, BouncePad.ActorUpVector);

		if(VisualizeComp.bSimulateHit)
		{
			FVector PlayerLocation = BouncePad.GetLaunchLocation();

			DrawWireSphere(PlayerLocation, 39, FLinearColor::Green, 3);

			if(BouncePad.bAlwaysAimAtLocation)
			{
				DrawWireSphere(BouncePad.GetAimAtLocationWorld(), 10, FLinearColor::Red, 3);
			}

			FPinballBouncePadHitResult HitResult;
			if(!BouncePad.CalculateBouncePadHitResult(HitResult))
			{
				return;
			}

			bool bHasAutoAim = HitResult.AutoAimTargetData.IsValid();
			FLinearColor DrawColor = bHasAutoAim ? FLinearColor::LucBlue : FLinearColor::Green;

			Pinball::AirMoveSimulation::VisualizePath(this, PlayerLocation, HitResult.GetImpulseVector(), BouncePad.LauncherComp, VisualizeComp.SimulatedInput, DrawColor, VisualizeComp.SimulationDuration, 0.016);
		}
	}
};
#endif