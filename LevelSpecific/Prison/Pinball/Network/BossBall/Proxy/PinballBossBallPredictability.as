UCLASS(Abstract)
class UPinballBossBallPredictability : UPinballPredictability
{
	// Proxy
	APinballBossBallProxy Proxy;

	// BossBall
	APinballBossBall BossBall;

	void Setup(APinballProxy InProxy) override
	{
		Super::Setup(InProxy);
		
		Proxy = Cast<APinballBossBallProxy>(InProxy);
		BossBall = Cast<APinballBossBall>(Proxy.RepresentedActor);
	}
};