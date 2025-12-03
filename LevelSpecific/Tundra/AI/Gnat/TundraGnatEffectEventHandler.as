UCLASS(Abstract)
class UTundraGnatEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSquashed(){};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartingTaunt(){};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLatchOn(){};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTelegraphLatchOn(){};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTargetedByMonkey(){};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitByThrownGnape(){};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGrabbedByMonkey(){};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnThrownByMonkey(){};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnClimbEntry(){};

	UFUNCTION(BlueprintPure)
	UTundraGnatHostComponent GetHostComponent()
	{
		auto GnatComp = UTundraGnatComponent::Get(Owner);
		if (GnatComp == nullptr)
			return nullptr;
		if (GnatComp.Host == nullptr)
			return nullptr;
		return UTundraGnatHostComponent::Get(GnatComp.Host); 
	}
}
