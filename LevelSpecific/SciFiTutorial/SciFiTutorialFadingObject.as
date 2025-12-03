event void FSciFiTutorialBlendObjectFinishedBlendEvent();

enum EAttachkedObjectsStart
{
	AfterDelay,
	AfterBlend
}

namespace SciFiTutorialBlendObject
{
	// Starts the blend of all actors that are at the top of the "linkage" tree.
	UFUNCTION()
	void StartBlendAllBlendObject()
	{
		TListedActors<ASciFiTutorialBlendObject> SciFiTutorialBlendObjects;
		for(ASciFiTutorialBlendObject SciFiTutorialBlendObject: SciFiTutorialBlendObjects)
		{
			if(SciFiTutorialBlendObject.AttachParentActor == nullptr)
		 		SciFiTutorialBlendObject.StartBlend();
		}
	}
}

UCLASS(Abstract)
class ASciFiTutorialBlendObject : AStaticMeshActor
{
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY(EditAnywhere, Category = "Blend")
	FHazeTimeLike BlendTimeLike;
	default BlendTimeLike.Duration = 1.0;

	UPROPERTY(EditAnywhere, Category = "Blend")
	float PlayRate = 1.0;
	
	UPROPERTY(EditAnywhere, Category = "Blend")
	EAttachkedObjectsStart AttachkedObjectsStart = EAttachkedObjectsStart::AfterDelay;

	UPROPERTY(EditAnywhere, Category = "Blend")
	float Delay = 0.0;

	UPROPERTY(EditAnywhere, Category = "Blend")
	FVector BlendDirection = FVector(0, 0, 1);

	UPROPERTY(EditAnywhere, Category = "Blend")
	bool bWorldSpace = false;

	UPROPERTY()
	FSciFiTutorialBlendObjectFinishedBlendEvent OnFinishedBlend;

	bool bActivated = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StaticMeshComponent.SetScalarParameterValueOnMaterials(n"WhitespaceBlend", 0);

		if(bWorldSpace)
			BlendDirection = BlendDirection;
		else
			BlendDirection = StaticMeshComponent.WorldTransform.TransformVector(BlendDirection);

		BlendDirection.Normalize();
		BlendDirection *= 0.8;

		StaticMeshComponent.SetVectorParameterValueOnMaterials(n"WhitespaceBlendDirection", BlendDirection);
		
		BlendTimeLike.SetPlayRate(PlayRate);
		BlendTimeLike.BindUpdate(this, n"UpdateBlend");
		BlendTimeLike.BindFinished(this, n"FinishBlend");
	}
	
	UFUNCTION()
	void ResetBlend()
	{
		if (!bActivated)
			return;
		
		bActivated = false;
		delayTimer.ClearTimer();

		StaticMeshComponent.SetScalarParameterValueOnMaterials(n"WhitespaceBlend", 0);

		TArray<AActor> ChildActors;
		GetAttachedActors(ChildActors);
		for (AActor Actor : ChildActors)
		{
			ASciFiTutorialBlendObject BlendObject = Cast<ASciFiTutorialBlendObject>(Actor);
			if(BlendObject != nullptr)
				BlendObject.ResetBlend();
		}
	}
	
	FTimerHandle delayTimer;

	UFUNCTION()
	void StartBlend()
	{
		if (bActivated)
			return;

		bActivated = true;
		
		if(Delay != 0)
			Timer::SetTimer(this, n"FinishDelay", Delay);
		else
			FinishDelay();
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateBlend(float CurValue)
	{
		StaticMeshComponent.SetScalarParameterValueOnMaterials(n"WhitespaceBlend", CurValue);
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishBlend()
	{
		OnFinishedBlend.Broadcast();
		if(AttachkedObjectsStart == EAttachkedObjectsStart::AfterBlend)
		{
			TArray<AActor> ChildActors;
			GetAttachedActors(ChildActors);
			for (AActor Actor : ChildActors)
			{
				ASciFiTutorialBlendObject BlendObject = Cast<ASciFiTutorialBlendObject>(Actor);
				if(BlendObject != nullptr)
					BlendObject.StartBlend();
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishDelay()
	{
		BlendTimeLike.PlayFromStart();

		if(AttachkedObjectsStart == EAttachkedObjectsStart::AfterDelay)
		{
			TArray<AActor> ChildActors;
			GetAttachedActors(ChildActors);
			for (AActor Actor : ChildActors)
			{
				ASciFiTutorialBlendObject BlendObject = Cast<ASciFiTutorialBlendObject>(Actor);
				if(BlendObject != nullptr)
					BlendObject.StartBlend();
			}
		}
	}
}