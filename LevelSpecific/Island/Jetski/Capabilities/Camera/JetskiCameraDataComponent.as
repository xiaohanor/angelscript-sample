UCLASS(NotBlueprintable)
class UJetskiCameraDataComponent : UActorComponent
{
	TInstigated<AActor> LookAtTarget;

	bool HasLookAtTarget() const
	{
		return LookAtTarget.Get() != nullptr;
	}

	AActor GetLookAtTarget() const
	{
		return LookAtTarget.Get();
	}
};

UFUNCTION(BlueprintCallable)
mixin void JetskiApplyLookAtTarget(AJetski Jetski, AActor LookAtTarget, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
{
	auto CameraDataComp = UJetskiCameraDataComponent::Get(Jetski);
	if(CameraDataComp == nullptr)
		return;

	CameraDataComp.LookAtTarget.Apply(LookAtTarget, Instigator, Priority);
}

UFUNCTION(BlueprintCallable)
mixin void JetskiClearLookAtTarget(AJetski Jetski, FInstigator Instigator)
{
	auto CameraDataComp = UJetskiCameraDataComponent::Get(Jetski);
	if(CameraDataComp == nullptr)
		return;

	CameraDataComp.LookAtTarget.Clear(Instigator);
}