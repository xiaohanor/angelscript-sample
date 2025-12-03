enum ETundraPlayerSnowMonkeyCeilingClimbExclusiveShape
{
	Sphere
}

struct FTundraPlayerSnowMonkeyCeilingExclusiveData
{
	ETundraPlayerSnowMonkeyCeilingClimbExclusiveShape ExclusiveShape;
	FTransform ExclusiveShapeTransform;
	float SphereRadius;

	bool IsPointInside(FVector Point)
	{
		switch(ExclusiveShape)
		{
			case ETundraPlayerSnowMonkeyCeilingClimbExclusiveShape::Sphere:
			{
				float SqrDist = Point.DistSquared(ExclusiveShapeTransform.Location);
				return SqrDist < Math::Square(SphereRadius);
			}
		}
	}

	FVector GetClosestPointInsideBlocker(FVector Point)
	{
		switch(ExclusiveShape)
		{
			case ETundraPlayerSnowMonkeyCeilingClimbExclusiveShape::Sphere:
			{
				FVector SphereToPoint = Point - ExclusiveShapeTransform.Location;
				FVector ClampedSphereToPoint = SphereToPoint.GetClampedToMaxSize(SphereRadius);
				FVector ClampedPoint = ExclusiveShapeTransform.Location + ClampedSphereToPoint;
				return ClampedPoint;
			}
		}
	}
}

class UTundraPlayerSnowMonkeyCeilingClimbExclusiveComponent : UHazeEditorRenderedComponent
{
	UPROPERTY(EditAnywhere)
	ETundraPlayerSnowMonkeyCeilingClimbExclusiveShape ExclusiveShape;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "ExclusiveShape == EPlayerSnowMonkeyCeilingClimbExclusiveShape::Sphere", EditConditionHides))
	float SphereRadius = 32.0;

	UPROPERTY(EditInstanceOnly)
	TArray<AActor> CeilingsToTarget;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for(int i = CeilingsToTarget.Num() - 1; i >= 0; i--)
		{
			AActor Actor = CeilingsToTarget[i];
			if(Actor == nullptr)
			{
				CeilingsToTarget.RemoveAt(i);
				continue;
			}

			auto ClimbComp = UTundraPlayerSnowMonkeyCeilingClimbComponent::Get(Actor);
			devCheck(ClimbComp != nullptr, "Ceiling Climb Blocking Component had an actor with no climb comp in CeilingsToBlock");
			ClimbComp.CeilingExclusiveComps.AddUnique(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		for(int i = CeilingsToTarget.Num() - 1; i >= 0; i--)
		{
			AActor Actor = CeilingsToTarget[i];
			if(Actor == nullptr)
				continue;

			auto ClimbComp = UTundraPlayerSnowMonkeyCeilingClimbComponent::Get(Actor);
			if(ClimbComp == nullptr)
				continue;

			ClimbComp.CeilingExclusiveComps.RemoveSingleSwap(this);
		}
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnComponentModifiedInEditor()
	{
		for(int i = CeilingsToTarget.Num() - 1; i >= 0; i--)
		{
			AActor Actor = CeilingsToTarget[i];
			if(Actor == nullptr)
				continue;

			auto ClimbComp = UTundraPlayerSnowMonkeyCeilingClimbComponent::Get(Actor);
			if(ClimbComp == nullptr)
			{
				CeilingsToTarget[i] = nullptr;
				PrintScaled("Select an actor with a ceiling climb component!", 5.f, FLinearColor::Red, 3.f);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void CreateEditorRenderState()
	{
		SetActorHitProxy();
		switch(ExclusiveShape)
		{
			case ETundraPlayerSnowMonkeyCeilingClimbExclusiveShape::Sphere:
			{
				DrawWireSphere(WorldLocation, SphereRadius, FLinearColor::Red, 3.0);
				break;
			}
		}
	}
#endif

	FTundraPlayerSnowMonkeyCeilingExclusiveData GetExclusiveDataForCeiling(UTundraPlayerSnowMonkeyCeilingClimbComponent Ceiling, bool bCalledFromEditor = false)
	{
		FTundraPlayerSnowMonkeyCeilingData CeilingData = Ceiling.GetCeilingData(bCalledFromEditor, true, false);
		return GetExclusiveDataForCeiling(CeilingData, bCalledFromEditor);
	}

	FTundraPlayerSnowMonkeyCeilingExclusiveData GetExclusiveDataForCeiling(FTundraPlayerSnowMonkeyCeilingData CeilingData, bool bCalledFromEditor = false)
	{
		FTundraPlayerSnowMonkeyCeilingExclusiveData Data;
		Data.ExclusiveShape = ExclusiveShape;
		Data.ExclusiveShapeTransform = WorldTransform;
		switch(ExclusiveShape)
		{
			case ETundraPlayerSnowMonkeyCeilingClimbExclusiveShape::Sphere:
			{
#if EDITOR
				if(!bCalledFromEditor)
				{
					TEMPORAL_LOG(Game::Mio, f"Ceiling Exclusive Component on \"{Owner.ActorNameOrLabel}\"")
						.Sphere("Sphere", WorldLocation, SphereRadius)
					;
				}
#endif

				Data.SphereRadius = SphereRadius;
				break;
			}
		}
		
		return Data;
	}
}