UCLASS(Abstract)
class UPinballBossBallProxyComponent : UPinballProxyComponent
{
	APinballBossBallProxy Proxy;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		Proxy = Cast<APinballBossBallProxy>(Owner);

#if !RELEASE
		TEMPORAL_LOG(this, Owner, "PinballBossBallProxy");
#endif
	}
};