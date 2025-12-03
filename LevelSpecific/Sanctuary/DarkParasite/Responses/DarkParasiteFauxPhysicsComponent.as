class UDarkParasiteFauxPhysicsComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(EditAnywhere, Category = "Physics")
	float PullForce = 1500.0;

	USceneComponent Component;
	FVector Location;
	USceneComponent OtherComponent;
	FVector OtherLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto ResponseComp = UDarkParasiteResponseComponent::GetOrCreate(Owner);
		ResponseComp.OnGrabbed.AddUFunction(this, n"HandleGrabbed");
		ResponseComp.OnReleased.AddUFunction(this, n"HandleReleased");
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (Component == nullptr ||
			OtherComponent == nullptr)
		{
			Component = nullptr;
			OtherComponent = nullptr;
			SetComponentTickEnabled(false);
			return;
		}

		FVector FromLocation = Component.WorldTransform.TransformPosition(Location);
		FVector ToLocation = OtherComponent.WorldTransform.TransformPosition(OtherLocation);

		const FVector Direction = (ToLocation - FromLocation).GetSafeNormal();
		const FVector Force = (Direction * PullForce);

		// Debug::DrawDebugPoint(FromLocation, 10.0, FLinearColor::Purple);
		// Debug::DrawDebugPoint(ToLocation, 10.0, FLinearColor::Green);
		// Debug::DrawDebugDirectionArrow(FromLocation, Direction, 100.0, 250.0, FLinearColor::Red, 5.0);

		FauxPhysics::ApplyFauxForceToParentsAt(Component, FromLocation, Force);
	}

	UFUNCTION()
	private void HandleGrabbed(AHazePlayerCharacter Instigator,
		FDarkParasiteTargetData AttachedData,
		FDarkParasiteTargetData GrabbedData)
	{
		if (!AttachedData.IsValid() ||
			!GrabbedData.IsValid())
			return;

		// Figure out which component is ours, we'll be pulling ourselves
		//  towards the other component to ensure our pull force is made of use
		//  ... we could do a ::Get() from attach side and apply force from there instead
		if (AttachedData.Actor == Owner)
		{
			Component = AttachedData.TargetComponent;
			Location = AttachedData.RelativeLocation;

			OtherComponent = GrabbedData.TargetComponent;
			OtherLocation = GrabbedData.RelativeLocation;
		}
		else
		{
			Component = GrabbedData.TargetComponent;
			Location = GrabbedData.RelativeLocation;

			OtherComponent = AttachedData.TargetComponent;
			OtherLocation = AttachedData.RelativeLocation;
		}

		// Always pull from/towards target center if the component is
		//  is a targetable
		auto Targetable = Cast<UTargetableComponent>(Component);
		auto OtherTargetable = Cast<UTargetableComponent>(OtherComponent);

		if (Targetable != nullptr)
			Location = FVector::ZeroVector;
		if (OtherTargetable != nullptr)
			OtherLocation = FVector::ZeroVector;

		SetComponentTickEnabled(true);
	}

	UFUNCTION()
	private void HandleReleased(AHazePlayerCharacter Instigator,
		FDarkParasiteTargetData AttachedData,
		FDarkParasiteTargetData GrabbedData)
	{
		Component = nullptr;
		OtherComponent = nullptr;
		SetComponentTickEnabled(false);
	}
}