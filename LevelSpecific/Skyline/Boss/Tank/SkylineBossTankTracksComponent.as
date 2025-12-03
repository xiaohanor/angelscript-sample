class USkylineBossTankTracksComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	FName MaterialParameter = n"OffsetX";

	UPROPERTY(EditAnywhere)
	FName PrimitiveComponentName = n"Mesh";

	UPROPERTY(EditAnywhere)
	TArray<FName> SlotNames;

	UPROPERTY(EditAnywhere)
	float SpeedScale = 0.00052;

	UPROPERTY(EditAnywhere)
	float DistanceFromCenter = 0.0;

	UPROPERTY(BlueprintReadOnly)
	TArray<UMaterialInstanceDynamic> MIDs;

	float Offset = 0.0;

	FVector PrevLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto PrimitiveComponent = UPrimitiveComponent::Get(Owner, PrimitiveComponentName);

		for (int i = 0; i < PrimitiveComponent.NumMaterials; i++)
		{
			if (SlotNames.Num() > 0)
			{
				if (SlotNames.Contains(PrimitiveComponent.MaterialSlotNames[i]))
					MIDs.Add(PrimitiveComponent.CreateDynamicMaterialInstance(i));
			}
			else
				MIDs.Add(PrimitiveComponent.CreateDynamicMaterialInstance(i));
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector TrackLocation = Owner.ActorTransform.TransformPositionNoScale(FVector::RightVector * DistanceFromCenter);
		FVector DeltaMove = TrackLocation - PrevLocation;
		float MoveDistance = DeltaMove.DotProduct(Owner.ActorForwardVector);
//		PrintToScreen("TankMoveDistance: " + MoveDistance, 0.0);
//		Debug::DrawDebugSphere(TrackLocation, 500.0, 12, FLinearColor::Green, 5.0, 0.0);

		Offset = Math::Wrap(Offset + (MoveDistance * SpeedScale), 0.0, 1.0);

		for (auto MID : MIDs)
			MID.SetScalarParameterValue(MaterialParameter, Offset);
	
		PrevLocation = TrackLocation;
	}
};