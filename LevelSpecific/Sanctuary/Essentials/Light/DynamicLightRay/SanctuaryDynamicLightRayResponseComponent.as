event void FSanctuaryDynamicLightRaySignature(USanctuaryDynamicLightRayResponseComponent ResponsComp);

class USanctuaryDynamicLightRayResponseComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly, Category = "LightRay Response|Reflection")
	bool bReflect = false;

	UPROPERTY(EditDefaultsOnly, Category = "LightRay Response|Reflection")
	float MaxReflectionAngle = 90.0;

	UPROPERTY(EditDefaultsOnly, Category = "LightRay Response|Components")
	bool bInvertComponentResponse = false;

	UPROPERTY(EditDefaultsOnly, Category = "LightRay Response|Components")
	TArray<FComponentReference> RespondingComponents;
	TArray<UPrimitiveComponent> RespondingPrimitives;

	TArray<FInstigator> ActiveInstigators;

	FSanctuaryDynamicLightRaySignature OnActivated;
	FSanctuaryDynamicLightRaySignature OnDeactived;

	ULightBirdResponseComponent LightBirdResponseComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for(FComponentReference ComponentRef : RespondingComponents)
		{
			UActorComponent Comp = ComponentRef.GetComponent(Owner);
			if(Comp == nullptr)
				continue;

			UPrimitiveComponent PrimitiveComp = Cast<UPrimitiveComponent>(Comp);
			if(PrimitiveComp == nullptr)
				continue;

			RespondingPrimitives.Add(PrimitiveComp);
		}
	
		LightBirdResponseComp = ULightBirdResponseComponent::Get(Owner);
	}

	bool IsRespondingComponent(UPrimitiveComponent Component)
	{
		if (RespondingComponents.Num() == 0)
			return true;

		return RespondingPrimitives.Contains(Component);
	}

	void Illuminate(FInstigator Instigator)
	{
		if (ActiveInstigators.Num() == 0)
		{
			if (LightBirdResponseComp != nullptr)
				LightBirdResponseComp.Illuminate();

			OnActivated.Broadcast(this);
		}

		ActiveInstigators.Add(Instigator);
	}

	void Unilluminate(FInstigator Instigator)
	{
		ActiveInstigators.Remove(Instigator);

		if (ActiveInstigators.Num() == 0)
		{
			if (LightBirdResponseComp != nullptr)
				LightBirdResponseComp.Unilluminate();

			OnDeactived.Broadcast(this);
		}
	}
};