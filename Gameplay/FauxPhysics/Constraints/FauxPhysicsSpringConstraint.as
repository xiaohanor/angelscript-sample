class UFauxPhysicsSpringConstraintVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UFauxPhysicsSpringConstraint;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(UActorComponent Component)
	{
		auto Spring = Cast<UFauxPhysicsSpringConstraint>(Component);
		Spring.DebugDraw(this);
	}
}

UCLASS(ClassGroup = FauxPhysics, Meta = (HideCategories = "LOD Physics AssetUserData Collision Tags Cooking Activation Rendering"))
class UFauxPhysicsSpringConstraint : USceneComponent
{
	FVector AnchorWorldLocation;

	// Force per 100/units
	UPROPERTY(Category = Spring, EditAnywhere)
	float SpringStrength = 1000.0;

	// If specified, the spring won't act a force if within this range
	UPROPERTY(Category = Spring, EditAnywhere)
	float MinimumRange = 0.0;

	// If >1, the spring will at most apply this much force, no matter how far its stretched
	UPROPERTY(Category = Spring, EditAnywhere)
	float MaximumForce = -1.0;

	UPROPERTY(Category = Spring, EditAnywhere, Meta = (EditCondition="AnchorAttachActor == nullptr", EditConditionHides, MakeEditWidget))
	FVector AnchorOffset;

	// If set, the anchor will be relative to this actor
	// In case this is set, use 'AnchorAttachOffset' to offset the anchor based on the attached actors transform
	UPROPERTY(Category = Spring, EditAnywhere)
	AActor AnchorAttachActor;

	// specify which component on the AnchorAttachActor we want. Leaving it blank will result in getting the root comp.
	UPROPERTY(Category = Spring, EditAnywhere, Meta = (EditCondition="AnchorAttachActor != nullptr", EditConditionHides))
	FName AnchorAttachComponentName = NAME_None;

	UPROPERTY(Category = Spring, EditAnywhere, Meta = (EditCondition="AnchorAttachActor != nullptr", EditConditionHides))
	FVector AnchorAttachOffset;

	UPROPERTY(Category = Spring, EditAnywhere, AdvancedDisplay)
	bool bDebugDraw = false;

	// Only apply the spring force to attached components on this actor, ignoring any attach parents on different actors
	UPROPERTY(Category = Spring, EditAnywhere, AdvancedDisplay)
	bool bOnlyApplySpringToThisActor = false;

	private FVector FinalForce;
	private float Distance;
	private TArray<FInstigator> DisableInstigators;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AnchorWorldLocation = WorldLocation + WorldTransform.TransformVector(AnchorOffset);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (AnchorAttachActor != nullptr)
		{
			FTransform AnchorTransform = AnchorAttachActor.ActorTransform;
			if(AnchorAttachComponentName != NAME_None)
			{
				USceneComponent AnchorComp = USceneComponent::Get(AnchorAttachActor, AnchorAttachComponentName);
				if(AnchorComp != nullptr)
				{
					AnchorTransform = AnchorComp.WorldTransform;
				}
			}
			AnchorWorldLocation = AnchorTransform.TransformPosition(AnchorAttachOffset);
		}

		if (bDebugDraw)
			DebugDraw();

		FVector SpringForce = (AnchorWorldLocation - WorldLocation);
		Distance = SpringForce.Size() - MinimumRange;
		if (Distance < 0.0)
			return;

		float Strength = Distance * (SpringStrength / 100.0);

		if (MaximumForce > 0.0 && Strength > MaximumForce)
			Strength = MaximumForce;

		FinalForce = SpringForce.SafeNormal * Strength;
		if (!FinalForce.IsNearlyZero())
			FauxPhysics::ApplyFauxForceToParentsAt(this, WorldLocation, FinalForce, bSameActorOnly = bOnlyApplySpringToThisActor);
	}

	UFUNCTION()
	void AddDisabler(FInstigator DisableInstigator)
	{
		DisableInstigators.AddUnique(DisableInstigator);
		AddComponentTickBlocker(DisableInstigator);
	}

	UFUNCTION()
	void RemoveDisabler(FInstigator DisableInstigator)
	{
		DisableInstigators.Remove(DisableInstigator);
		RemoveComponentTickBlocker(DisableInstigator);
	}


	FVector GetSpringVelocity()
	{
		return FinalForce;
	}

	float GetDistanceFromOrigin()
	{
		return Distance;
	}

	void DebugDraw(UHazeScriptComponentVisualizer Visualizer = nullptr)
	{
		if(Visualizer == nullptr || Visualizer.EditingComponent == nullptr)
			return;

		if(!Editor::IsComponentSelected(Visualizer.EditingComponent) && !Visualizer.EditingComponent.World.IsPreviewWorld())
			return;

		FVector Source = WorldLocation;
		FVector Target = AnchorWorldLocation;

		// We're in editor, so "AnchorWorldLocation" isn't valid
		if (!World.IsGameWorld())
		{
			if (AnchorAttachActor != nullptr)
			{
				FTransform AnchorTransform = AnchorAttachActor.ActorTransform;
				if(AnchorAttachComponentName != NAME_None)
				{
					USceneComponent AnchorComp = USceneComponent::Get(AnchorAttachActor, AnchorAttachComponentName);
					if(AnchorComp != nullptr)
					{
						AnchorTransform = AnchorComp.WorldTransform;
					}
				}
				Target = AnchorTransform.TransformPosition(AnchorAttachOffset);
			}
			else
			{
				Target = WorldLocation + WorldTransform.TransformVector(AnchorOffset);
			}
		}

		int CoilCount = 10;
		float CoilWidth = 40.0;

		const int Resolution = 20;

		FVector Direction = (Target - Source).SafeNormal;
		FVector Up = FauxPhysics::Calculation::GetArbitraryPerpendicular(Direction);
		FVector Right = Direction.CrossProduct(Up);

		float SourceDistance = Source.Distance(Target);
		FVector Step = Direction * (SourceDistance / CoilCount);

		float AngleStep = TWO_PI / Resolution;

		FLinearColor DebugColor = SourceDistance - MinimumRange <= 0 ? FLinearColor::Blue : FLinearColor::Red;

		for(int i = 0; i < CoilCount; ++i)
		{
			FVector Start = Source + Step * i;
			for(int a = 0; a < Resolution; ++a)
			{
				FVector StepStart = Step * (a / float(Resolution));
				FVector StepEnd = Step * ((a + 1) / float(Resolution));
				float AngleStart = AngleStep * a;
				float AngleEnd = AngleStep * (a + 1);

				FVector LineStart =
					Up * Math::Cos(AngleStart) +
					Right * Math::Sin(AngleStart);

				FVector LineEnd =
					Up * Math::Cos(AngleEnd) +
					Right * Math::Sin(AngleEnd);

				if (Visualizer == nullptr)
					Debug::DrawDebugLine(Start + StepStart + LineStart * CoilWidth, Start + StepEnd + LineEnd * CoilWidth, DebugColor, 5.0);
				else
					Visualizer.DrawLine(Start + StepStart + LineStart * CoilWidth, Start + StepEnd + LineEnd * CoilWidth, DebugColor, 5.0);
			}
		}

		Visualizer.DrawPoint(Source, FLinearColor::Yellow, 20);
		Visualizer.DrawPoint(Target, FLinearColor::Yellow, 20);
	}

	UFUNCTION(Category = Helpers, CallInEditor)
	void SetMinimumRangeToDistanceToAnchor()
	{
		FVector Source = WorldLocation;
		FVector Target = AnchorWorldLocation;

		// We're in editor, so "AnchorWorldLocation" isn't valid
		if (!World.IsGameWorld())
		{
			if (AnchorAttachActor != nullptr)
			{
				FTransform AnchorTransform = AnchorAttachActor.ActorTransform;
				if(AnchorAttachComponentName != NAME_None)
				{
					USceneComponent AnchorComp = USceneComponent::Get(AnchorAttachActor, AnchorAttachComponentName);
					if(AnchorComp != nullptr)
					{
						AnchorTransform = AnchorComp.WorldTransform;
					}
				}
				Target = AnchorTransform.TransformPosition(AnchorAttachOffset);
			}
			else
			{
				Target = WorldLocation + WorldTransform.TransformVector(AnchorOffset);
			}
		}

		MinimumRange = (Target-Source).Size();
	}

}