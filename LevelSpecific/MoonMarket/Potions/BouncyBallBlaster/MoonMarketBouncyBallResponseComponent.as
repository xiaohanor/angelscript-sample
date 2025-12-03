event void FMoonMarketOnHitByBall(FMoonMarketBouncyBallHitData Data);

struct FMoonMarketBouncyBallHitData
{
	AHazePlayerCharacter InstigatingPlayer;
	AMoonMarketBouncyBall Ball;
	FVector ImpactPoint;
	FVector ImpactNormal;
	FVector ImpactVelocity;
}

class UMoonMarketBouncyBallResponseComponent : UActorComponent
{
	FMoonMarketOnHitByBall OnHitByBallEvent;
	const float MinResponseAngleDot = -0.3;
	const float MinResponseVelocity = 10;

	void Hit(FMoonMarketBouncyBallHitData Data)
	{
		float Dot = Data.ImpactVelocity.GetSafeNormal().DotProduct(Data.ImpactNormal);
		if(Dot > MinResponseAngleDot)
			return;

		OnHitByBallEvent.Broadcast(Data);
	}
};
