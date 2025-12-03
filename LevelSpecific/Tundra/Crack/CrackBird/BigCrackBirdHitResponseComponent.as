event void FOnCrackBirdHit(ABigCrackBird Bird, FVector BirdLocation);

class UBigCrackBirdHitResponseComponent : UActorComponent
{
	UPROPERTY()
	FOnCrackBirdHit OnBigCrackBirdHit;
}