struct FDarkPortalGrabData
{
	UPROPERTY(BlueprintReadOnly)
	UDarkPortalTargetComponent TargetComponent = nullptr;
	UPROPERTY(BlueprintReadOnly)
	UDarkPortalResponseComponent ResponseComponent = nullptr;
	UPROPERTY(BlueprintReadOnly)
	FVector RelativeLocation = FVector::ZeroVector;
	UPROPERTY(BlueprintReadOnly)
	FVector RelativeNormal = FVector::ForwardVector;
	UPROPERTY(BlueprintReadOnly)
	FName SocketName = NAME_None;

	/**
	 * 
	 * Random positions, per tentacle, that are sent to nigara.
	 * 
	 * IMO, this should be removed and we should force generate points on the targetableComponent instead.
	 * 
	 * The reason why we are doing this is because it looks strange if all 20+ arms go to the exact same vector location,
	 * which will happen if there are no points generated, or if there is no mesh with collision available on the actor.
	 * 
	 * We'll keep this for now. 
	 */
	TArray<FVector> RelativeTargetLocations;
	
	float Timestamp = 0.0;
	bool bHasTriggeredResponse = false;

	FDarkPortalGrabData(UDarkPortalTargetComponent InTargetComponent,
		UDarkPortalResponseComponent InResponseComponent,
		FVector InWorldLocation = FVector::ZeroVector,
		FVector InWorldNormal = FVector::ForwardVector,
		FName InSocketName = NAME_None)
	{
		TargetComponent = InTargetComponent;
		ResponseComponent = InResponseComponent;
		RelativeLocation = InWorldLocation;

		/**
		 * Spread out the tentacle tangents at the target by giving each grab their own normal
		 * .. This is questionable because it might cause problems in the level due to 
		 * diverging from the, potentially, user set normal. 
		 * 
		 * It generates random directions in a cone, with the WorldNormal
		 * that the user has set as the center direction. 	
		 * 
		 * // sydney
		 */
		FVector RandomConeWorldNormal = Math::GetRandomConeDirection(InWorldNormal,
		Math::DegreesToRadians(70.0),
		Math::DegreesToRadians(0.0)
		);
		RandomConeWorldNormal.Normalize();

		RelativeNormal = RandomConeWorldNormal;

		SocketName = InSocketName;

		Timestamp = Time::GameTimeSeconds;
		bHasTriggeredResponse = false;

		if (TargetComponent != nullptr)
		{
			RelativeLocation = TargetComponent
				.GetSocketTransform(SocketName)
				.InverseTransformPosition(InWorldLocation);

			RelativeNormal = TargetComponent
				.GetSocketTransform(SocketName)
				.InverseTransformVector(RandomConeWorldNormal);
		}

		// @TODO: remove this and instead auto generate locations on the TargetableComp. That array of points should then be sent to niagara.
		AssignRelativeTargetLocations(InTargetComponent, InWorldLocation);
	}

	void AssignRelativeTargetLocations(UDarkPortalTargetComponent InTargetComponent, const FVector GrabPoint)
	{
		// try to get locations on the parent mesh to grab...
		const auto ParentComp = InTargetComponent.GetAttachParent();
		const UPrimitiveComponent PrimParent = Cast<UPrimitiveComponent>(ParentComp);
		if(PrimParent == nullptr)
		{
			// we don't have the expected setup... lets find something targetable on the actor
			const AActor TargetActor = InTargetComponent.GetOwner();
			PrimParent = UPrimitiveComponent::Get(TargetActor);
		}

		if(PrimParent == nullptr)
		{
			// couldn't find any prim, abort.
			return;
		}

		FVector QueryLocation = FVector::ZeroVector;
		if(InTargetComponent.GrabPoints.Num() == 0)
			QueryLocation = InTargetComponent.GetWorldLocation();
		else
			QueryLocation = GrabPoint;

		// gather sample points.. (We need less sample points if we have more arms)
		const int NumSamples = 10;		
		const float SearchDistance = 100.0;
		RelativeTargetLocations.Reserve(NumSamples);
		for(int i = 0; i < NumSamples; ++i)
		{

			FVector RandomSphereQueryLocation = QueryLocation + (Math::GetRandomPointInSphere() * SearchDistance);

			FVector PointOnMesh_WS = RandomSphereQueryLocation;
			auto DistanceToClosest = PrimParent.GetClosestPointOnCollision(
				RandomSphereQueryLocation,
				PointOnMesh_WS
			);

			if(DistanceToClosest > SearchDistance ||DistanceToClosest <= 0.0)
			{
				// reset if its to far away. Which might happen if the 
				// targetComp is being moved around a lot during gameplay
				PointOnMesh_WS = RandomSphereQueryLocation;
			}

			// Debug::DrawDebugPoint(
			// 	PointOnMesh_WS,
			// 	20.0,
			// 	FoundClosest > 0.0 ? FLinearColor::Yellow : FLinearColor::Red,
			// 	2.0
			// );

			const FVector PointOnMesh_LS = InTargetComponent.GetWorldTransform().InverseTransformPosition(PointOnMesh_WS);

			RelativeTargetLocations.Add(PointOnMesh_LS);
		}

	}

	FVector GetWorldLocation() const property
	{
		if(TargetComponent == nullptr)
		{
			devError("Tentacles: We are trying to get WorldLocation of the target to early. TargetComp == null");
			return FVector::ZeroVector;
		}

		return TargetComponent
			.GetSocketTransform(SocketName)
			.TransformPosition(RelativeLocation);
	}

	FVector GetWorldNormal() const property
	{
		if(TargetComponent == nullptr)
		{
			devError("Tentacles: We are trying to get WorldNormal of the target to early. TargetComp == null");
			return FVector::ZeroVector;
		}

		return TargetComponent
			.GetSocketTransform(SocketName)
			.TransformVector(RelativeNormal);
	}

	FTransform GetWorldTransform() const property
	{
		return FTransform(
			WorldNormal.ToOrientationQuat(),
			WorldLocation,
		);
	}

	AActor GetActor() const property
	{
		if (TargetComponent == nullptr)
			return nullptr;

		return TargetComponent.Owner;
	}

	bool IsValid() const
	{
		if (TargetComponent == nullptr)
			return false;
		if (TargetComponent.IsBeingDestroyed())
			return false;
		if (TargetComponent.Owner == nullptr)
			return false;
		if (TargetComponent.Owner.IsActorBeingDestroyed())
			return false;

		return true;
	}
}