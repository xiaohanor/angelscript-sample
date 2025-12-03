class UMeltdownWorldSpinMatchRotationComponent : UActorComponent
{
	FQuat StartRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartRotation = Owner.ActorQuat;
		Owner.RootComponent.Mobility = EComponentMobility::Movable;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		auto Manager = AMeltdownWorldSpinManager::GetWorldSpinManager();
		Owner.SetActorRotation(Manager.WorldSpinRotation * StartRotation);
	}
};