
UCLASS(ClassGroup = FauxPhysics, Meta = (HideCategories = "LOD Physics AssetUserData Collision Tags Cooking Activation Rendering"))
class UFauxPhysicsWeightComponent : USceneComponent
{
	UPROPERTY(Category = Weight, EditAnywhere)
	bool bApplyGravity = true;

	UPROPERTY(Category = Weight, EditAnywhere)
	bool bApplyInertia = false;

	UPROPERTY(Category = Weight, EditAnywhere)
	float MassScale = 1.0;

	UFauxPhysicsComponentBase ParentComponent;

	FVector PreviousLocation = FVector::ZeroVector;
	FVector PreviousVelocity = FVector::ZeroVector;

	private FVector GravityDir_Internal = -FVector::UpVector;

	private TArray<FInstigator> DisableInstigators;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		USceneComponent Parent = AttachParent;
		while(Parent != nullptr)
		{
			ParentComponent = Cast<UFauxPhysicsComponentBase>(Parent);
			if (ParentComponent != nullptr)
				break;

			Parent = Parent.AttachParent;
		}

		if (ParentComponent == nullptr)
		{
			devError("FauxPhysicsWeightComponent added without finding a FauxPhysicsComponent somewhere in the parents.");
			return;
		}

		PreviousLocation = ParentComponent.WorldLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bApplyInertia)
		{
			FVector DeltaMove = ParentComponent.WorldLocation - PreviousLocation;
			FVector NewVelocity = DeltaMove / DeltaTime;

			FVector DeltaVelocity = NewVelocity - PreviousVelocity;
			ParentComponent.ApplyImpulse(WorldLocation, -DeltaVelocity * MassScale);

			PreviousVelocity = NewVelocity;
			PreviousLocation = ParentComponent.WorldLocation;
		}

		if (bApplyGravity)
		{
			FauxPhysics::ApplyFauxForceToParentsAt(this, WorldLocation, GravityDir_Internal * 5500.0 * MassScale);
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

	FVector GetGravityDir() const property
	{
		return GravityDir_Internal;
	}

	void SetGravityDir(FVector InGravityDir)
	{
		GravityDir_Internal = InGravityDir;
	}

	UFUNCTION(BlueprintCallable)
	void ResetInternalState()
	{
		PreviousVelocity = FVector::ZeroVector;
		PreviousLocation = ParentComponent.WorldLocation;
	}
}