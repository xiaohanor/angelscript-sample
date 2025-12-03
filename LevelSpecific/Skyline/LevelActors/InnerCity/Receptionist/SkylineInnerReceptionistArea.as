class ASkylineInnerReceptionistArea : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;

	UPROPERTY(DefaultComponent)
	USphereComponent Area;
	default Area.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default Area.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);
};