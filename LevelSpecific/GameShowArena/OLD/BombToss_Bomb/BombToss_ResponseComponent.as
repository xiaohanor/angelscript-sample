event void FBombTossImpactSignature(FVector Location, FVector Normal);

class UBombTossResponseComponent : UActorComponent
{
	UPROPERTY()
	FBombTossImpactSignature OnImpact;

	TArray<FInstigator> ImpactBlockers;
	TArray<USceneComponent> ValidComponentsToImpact;

	void AddImpactBlocker(FInstigator Instigator)
	{
		ImpactBlockers.AddUnique(Instigator);
	}

	void RemoveImpactBlocker(FInstigator Instigator)
	{
		ImpactBlockers.RemoveSingleSwap(Instigator);
	}

	bool IsImpactBlocked()
	{
		return ImpactBlockers.Num() > 0;
	}

	void TryApplyImpact(USceneComponent Component, FVector Location, FVector Normal)
	{
		if(IsImpactBlocked())
			return;

		if(Component != nullptr && ValidComponentsToImpact.Num() > 0 && !ValidComponentsToImpact.Contains(Component))
			return;

		OnImpact.Broadcast(Location, Normal);
	}
}