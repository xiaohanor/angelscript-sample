class UIslandRedBlueStickyGrenadeBounceOffComponent : UActorComponent
{
	/* Will reflect current velocity on the surface and multiply it with this value. */
	UPROPERTY(EditAnywhere)
	float BounceImpulseMultiplier = 0.2;

	/* When a bounce is triggered at least this velocity will be applied in the normal direction. */
	UPROPERTY(EditAnywhere)
	float BounceMinVelocityAlongNormal = 800.0;
}