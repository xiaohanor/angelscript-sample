UCLASS(Abstract)
class UMoonMarketYarnBallPotionComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<AMoonMarketYarnBall> YarnClass;

	bool bForceJump = false;
};