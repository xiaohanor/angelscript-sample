
class UPhysicsForceComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UFauxPhysicsForceComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(UActorComponent Component)
	{
		UFauxPhysicsForceComponent ForceComponent = Cast<UFauxPhysicsForceComponent>(Component);
		FVector Origin = ForceComponent.WorldLocation;
		FVector Force = ForceComponent.Force;

		if (ForceComponent.bWorldSpace)
		{
			DrawArrow(Origin, Origin + Force * 0.2, FLinearColor::Yellow, 25.0, 3.0);
		}
		else
		{
			Force = ForceComponent.WorldTransform.TransformVector(Force);
			DrawArrow(Origin, Origin + Force * 0.2, FLinearColor::Yellow, 25.0, 3.0);
		}
	}
}

UCLASS(ClassGroup = FauxPhysics, Meta = (HideCategories = "LOD Physics AssetUserData Collision Tags Cooking Activation Rendering"))
class UFauxPhysicsForceComponent : USceneComponent
{
	UPROPERTY(Category = Force, EditAnywhere)
	FVector Force;

	UPROPERTY(Category = Force, EditAnywhere)
	bool bWorldSpace = true;

	// Only apply the force to attached components on this actor, ignoring any attach parents on different actors
	UPROPERTY(Category = Force, EditAnywhere, AdvancedDisplay)
	bool bOnlyApplyForceToThisActor = false;

	TArray<FInstigator> DisableInstigators;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bWorldSpace)
		{
			FauxPhysics::ApplyFauxForceToParentsAt(this, WorldLocation, Force,
				bSameActorOnly = bOnlyApplyForceToThisActor);
		}
		else
		{
			FauxPhysics::ApplyFauxForceToParentsAt(this, WorldLocation, WorldTransform.TransformVector(Force),
				bSameActorOnly = bOnlyApplyForceToThisActor);
		}
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

	UFUNCTION(BlueprintPure)
	bool IsEnabled()
	{
		return DisableInstigators.Num() == 0;
	}
}