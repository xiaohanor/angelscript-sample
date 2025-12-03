class ATundraPondBeastBaitTrigger : AActorTrigger
{
	default BrushComponent.SetCollisionResponseToChannel(ECollisionChannel::WeaponTracePlayer, ECollisionResponse::ECR_Block);	

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;
}