event void FSanctuaryFragmentManagerComponentSignature();

class USanctuaryFragmentManagerComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	TArray<AActor> Fragments;

	UPROPERTY()
	FSanctuaryFragmentManagerComponentSignature OnAssembled;

	UPROPERTY()
	FSanctuaryFragmentManagerComponentSignature OnBreak;

	bool bAssembled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (auto Fragment : Fragments)
		{
			auto TransformingSceneComponent = UTransformingSceneComponent::Get(Fragment);
			if (TransformingSceneComponent != nullptr)
			{
				TransformingSceneComponent.OnTransformBegin.AddUFunction(this, n"OnTransformBegin");
				TransformingSceneComponent.OnTransformComplete.AddUFunction(this, n"OnTransformComplete");			
			}
		}
	}

	UFUNCTION()
	private void OnTransformBegin()
	{
		if (bAssembled)
		{
			bAssembled = false;
			OnBreak.Broadcast();
		}
	}

	UFUNCTION()
	private void OnTransformComplete()
	{
		int FragmentsInPlace = 0;

		for (auto Fragment : Fragments)
		{
			auto TransformingSceneComponent = UTransformingSceneComponent::Get(Fragment);

			if (TransformingSceneComponent != nullptr && TransformingSceneComponent.bTransformComplete)
				FragmentsInPlace++;
		}

		if (FragmentsInPlace == Fragments.Num())
		{
			bAssembled = true;
			OnAssembled.Broadcast();
		}
	}
}